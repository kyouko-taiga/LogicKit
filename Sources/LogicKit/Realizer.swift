/// Base class for realizers.
class RealizerBase: IteratorProtocol {

  public typealias Element = [String: Term]

  fileprivate init() {}

  public func next() -> [String: Term]? {
    fatalError("not implemented")
  }

}

/// Realizer that alternatively pulls results from multiple sub-realizers.
final class RealizerAlternator: RealizerBase {

  init<S>(realizers: S) where S: Sequence, S.Element == Realizer {
    self.realizers = Array(realizers)
  }

  private var index = 0
  private var realizers: [Realizer]

  public override func next() -> [String: Term]? {
    while !realizers.isEmpty {
      guard let result = realizers[index].next() else {
        realizers.remove(at: index)
        if !realizers.isEmpty {
          index = index % realizers.count
        }
        continue
      }
      index = (index + 1) % realizers.count
      return result
    }
    return nil
  }

}

/// Standard goal realizer.
final class Realizer: RealizerBase {

  init(
    goals: [Term],
    knowledge: KnowledgeBase,
    parentBindings: BindingMap = [:],
    logger: Logger? = nil)
  {
    self.goals = goals
    self.knowledge = knowledge
    self.parentBindings = parentBindings
    self.logger = logger

    // Identify which part of the knowledge base the realizer should explore.
    assert(goals.count > 0)
    switch goals.first! {
    case ._term(let name, _):
      clauseIterator = knowledge.predicates[name].map { AnyIterator($0.makeIterator()) }
    case ._rule(let name, _, _):
      clauseIterator = knowledge.predicates[name].map { AnyIterator($0.makeIterator()) }
    default:
      clauseIterator = AnyIterator(knowledge.literals.makeIterator())
    }
  }

  /// The goals to realize.
  private let goals: [Term]
  /// The knowledge base.
  private let knowledge: KnowledgeBase
  /// The bindings already  determined by the parent realizer.
  private let parentBindings: BindingMap
  /// The optional logger, for debug purpose.
  private var logger: Logger?

  /// An iterator on the knowledge clauses to check.
  private var clauseIterator: AnyIterator<Term>?
  /// The subrealizer, if any.
  private var subRealizer: RealizerBase? = nil

  public override func next() -> [String: Term]? {
    // If we have a subrealizer running, pull its results first.
    if let sub = subRealizer {
      if let result = sub.next() {
        return result
          .merged(with: parentBindings)
      } else {
        logger?.didBacktrack()
        subRealizer = nil
      }
    }

    let goal = goals.first!
    logger?.willRealize(goal: goal)

    // Check for the built-in `~=~/2` predicate.
    if case ._term("lk.~=~", let args) = goal {
      assert(args.count == 2)
      if let nodeResult = unify(goal: args[0], fact: args[1]) {
        if goals.count > 1 {
          let subGoals = goals.dropFirst().map(nodeResult.deepWalk)
          subRealizer = Realizer(
            goals: subGoals, knowledge: knowledge, parentBindings: nodeResult, logger: logger)
          if let branchResult = subRealizer!.next() {
            return branchResult
              .merged(with: parentBindings)
          }
        } else {
          return nodeResult
            .merged(with: parentBindings)
        }
      }
    }

    // Look for the next root clause.
    while let clause = clauseIterator?.next() {
      logger?.willAttempt(clause: clause)

      switch (goal, clause) {
      case (.val(let lvalue), .val(let rvalue)) where lvalue == rvalue:
        if goals.count > 1 {
          let subGoals = Array(goals.dropFirst())
          subRealizer = Realizer(goals: subGoals, knowledge: knowledge, logger: logger)
          if let branchResult = subRealizer!.next() {
            return branchResult
              .merged(with: parentBindings)
          }
        }

      case (._term, ._term):
        if let nodeResult = unify(goal: goal, fact: clause) {
          if goals.count > 1 {
            let subGoals = goals.dropFirst().map(nodeResult.deepWalk)
            subRealizer = Realizer(
              goals: subGoals, knowledge: knowledge, parentBindings: nodeResult, logger: logger)
            if let branchResult = subRealizer!.next() {
              return branchResult
                .merged(with: parentBindings)
            }
          } else {
            return nodeResult
              .merged(with: parentBindings)
          }
        }

      case let (._term(goalName, _), ._rule(ruleName, ruleArgs, ruleBody)):
        assert(goalName == ruleName)

        // First we try to unify the rule head with the goal.
        let head: Term = ._term(name: goalName, arguments: ruleArgs)
        if let nodeResult = unify(goal: goal, fact: head) {
          let subGoals = goals.dropFirst()
            .map(nodeResult.deepWalk)
          let ruleGoals = ruleBody.goals
            .map({ $0.map(nodeResult.deepWalk) + subGoals })
          assert(!ruleGoals.isEmpty)

          // We have to make sure bound knowledge variables are renamed in the sub-realizer's
          // knowledge, otherwise they may collide with the ones we already bound. For instance,
          // consider a recursive rule `p(q($x), $y) ⊢ p($x, q($y))` and a goal `p($z, 0)`. `$z`
          // would get bound to `q($x)` and `$y` to `0` before we try satisfy `p($x, q(0))`. But
          // if `$x` wasn't renamed, we'd be trying to unify `$x` with `q($x)` while recursing.
          let subKnowledge = knowledge.renaming(Set(clause.variables))
          let subRealizers = ruleGoals.map {
            Realizer(
              goals: $0, knowledge: subKnowledge, parentBindings: nodeResult, logger: logger)
          }
          subRealizer = subRealizers.count > 1
            ? RealizerAlternator(realizers: subRealizers)
            : subRealizers[0]

          if let branchResult = subRealizer!.next() {
            // Note the `branchResult` already contains the bindings of `nodeResult`, as the these
            // will have been merged by sub-realizer.
            return branchResult
              .merged(with: parentBindings)
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
        if let b = unify(goal: larg, fact: rarg, knowing: intermediateResult) {
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

}
