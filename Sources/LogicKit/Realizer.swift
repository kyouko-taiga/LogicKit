public struct RealizerAlternator: IteratorProtocol, Sequence {

    init<S>(realizers: S) where S: Sequence, S.Element == Realizer {
        self.realizers = Array(realizers)
    }

    public mutating func next() -> [String: Term]? {
        while !self.realizers.isEmpty {
            guard let result = self.realizers[self.index].next() else {
                self.realizers.remove(at: index)
                if !self.realizers.isEmpty {
                    self.index = self.index % self.realizers.count
                }
                continue
            }
            self.index = (self.index + 1) % self.realizers.count
            return result
        }
        return nil
    }

    public func makeIterator() -> RealizerAlternator {
        return self
    }

    var index    : Int = 0
    var realizers: [Realizer]

}

struct Realizer: IteratorProtocol {

    init(
        goals         : [Term],
        knowledge     : KnowledgeBase,
        parentBindings: BindingMap = [:],
        logger        : Logger? = nil)
    {
        self.goals          = goals
        self.knowledge      = knowledge
        self.parentBindings = parentBindings
        self.logger         = logger
    }

    mutating func next() -> [String: Term]? {
        // If we have a subrealizer running, pull its results first.
        if let result = self.subRealizer?.next() {
            return result
              .merged(with: parentBindings)
              .reified()
        } else {
            if self.subRealizer != nil {
                self.logger?.log(message: "backtacking", fontAttributes: [.dim])
                self.subRealizer = nil
            }
        }

        let goal = self.goals.first!
        self.logger?.log(message: "Attempting to realize ", terminator: "")
        self.logger?.log(message: goal.description, fontAttributes: [.bold])

        // Check for the built-in `~=~/2` predicate.
        if case ._term("lk.~=~", let args) = goal {
            assert(args.count == 2)
            if let nodeResult = self.unify(goal: args[0], fact: args[1]) {
                if self.goals.count > 1 {
                    let subGoals     = self.goals.dropFirst().map(nodeResult.deepWalk)
                    self.subRealizer = RealizerAlternator(realizers: [
                        Realizer(
                            goals         : subGoals,
                            knowledge     : self.knowledge,
                            parentBindings: nodeResult,
                            logger        : self.logger)
                    ])
                    if let branchResult = self.subRealizer!.next() {
                        return branchResult
                            .merged(with: parentBindings)
                            .reified()
                    }
                } else {
                    return nodeResult
                        .merged(with: parentBindings)
                        .reified()
                }
            }
        }

        // Look for the next root clause.
        while self.clauseIndex != self.knowledge.endIndex {
            let clause = self.knowledge[self.clauseIndex]
            self.clauseIndex += 1

            self.logger?.log(message: "using "    , terminator: "", fontAttributes: [.dim])
            self.logger?.log(message: "\(clause) ")

            switch (goal, clause) {
            case (.val(let lvalue), .val(let rvalue)) where lvalue == rvalue:
                if self.goals.count > 1 {
                    let subGoals     = Array(self.goals.dropFirst())
                    self.subRealizer = RealizerAlternator(realizers: [
                        Realizer(goals: subGoals, knowledge: self.knowledge, logger: self.logger)
                    ])
                    if let branchResult = self.subRealizer!.next() {
                        return branchResult
                            .merged(with: parentBindings)
                            .reified()
                    }
                }

            case (._term(_, _), ._term(_, _)):
                if let nodeResult = self.unify(goal: goal, fact: clause) {
                    if self.goals.count > 1 {
                        let subGoals     = self.goals.dropFirst().map(nodeResult.deepWalk)
                        self.subRealizer = RealizerAlternator(realizers: [
                            Realizer(
                                goals         : subGoals,
                                knowledge     : self.knowledge,
                                parentBindings: nodeResult,
                                logger        : self.logger)
                        ])
                        if let branchResult = self.subRealizer!.next() {
                            return branchResult
                                .merged(with: parentBindings)
                                .reified()
                        }
                    } else {
                        return nodeResult
                            .merged(with: parentBindings)
                            .reified()
                    }
                }

            case let (._term(goalName, _), ._rule(ruleName, ruleArguments, ruleBody))
                where goalName == ruleName:

                // First we try to unify the rule head with the goal.
                let head: Term = ._term(name: goalName, arguments: ruleArguments)
                if let nodeResult = self.unify(goal: goal, fact: head) {
                    let subGoals  = self.goals.dropFirst()
                        .map(nodeResult.deepWalk)
                    let ruleGoals = ruleBody.goals
                        .map({ $0.map(nodeResult.deepWalk) + subGoals })

                    // Note that we have to make sure all variables of the sub-realizer's knowldge
                    // are fresh, otherwise they may collide with the ones we already bound. For
                    // instance, consider a recursive rule `p(q($x), $y) ⊢ p($x, q($y))` and a
                    // goal `p($z, 0)`. In this example, `$z` would get bound to `q($x)` and `$y`
                    // to `0` before we try satisfy `p($x, q(0))`. But if `$x` wasn't renamed,
                    // we'd be trying to unify `$x` with `q($x)` while recursing.

                    self.subRealizer = RealizerAlternator(realizers: ruleGoals.map({
                        Realizer(
                            goals         : $0,
                            knowledge     : self.knowledge.refreshed,
                            parentBindings: nodeResult,
                            logger        : self.logger)
                    }))
                    if let branchResult = self.subRealizer!.next() {
                        return nodeResult
                            .merged(with: branchResult)
                            .merged(with: parentBindings)
                            .reified()
                    }
                }

            default:
                break
            }
        }

        return nil
    }

    func unify(goal: Term, fact: Term, knowing bindings: BindingMap = [:]) -> BindingMap? {
        // Shallow-walk the terms to unify.
        let lhs = bindings.shallowWalk(goal)
        let rhs = bindings.shallowWalk(fact)

        // Equal terms always unify.
        if lhs == rhs {
            return bindings
        }

        switch (lhs, rhs) {
        case let (.var(name), _):
            switch bindings[name] {
            case .none: return bindings.binding(name, to: rhs)
            case rhs? : return bindings
            default   : return nil
            }

        case let (_, .var(name)):
            switch bindings[name] {
            case .none: return bindings.binding(name, to: lhs)
            case lhs? : return bindings
            default   : return nil
            }

        case let (.val(lvalue), .val(rvalue)):
            return lvalue == rvalue
                ? bindings
                : nil

        case let (._term(lname, largs), ._term(rname, rargs)) where lname == rname:
            // Make sure both terms are of same arity.
            guard largs.count == rargs.count else { return nil }

            // Try unify subterms (i.e. arguments).
            var intermediateResult = bindings
            for (larg, rarg) in zip(largs, rargs) {
                if let b = self.unify(goal: larg, fact: rarg, knowing: intermediateResult) {
                    intermediateResult = b
                } else {
                    return nil
                }
            }

            // Unification succeeded.
            return intermediateResult

        default:
            return nil
        }
    }

    let goals         : [Term]
    let knowledge     : KnowledgeBase
    let parentBindings: BindingMap
    var logger        : Logger?

    var clauseIndex   : Int = 0
    var subRealizer   : RealizerAlternator? = nil

}
