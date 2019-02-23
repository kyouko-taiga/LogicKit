/// Base class for realizers.
public class RealizerBase: IteratorProtocol, Sequence {

  public typealias Element = [String: Term]

  fileprivate init() {}

  public func next() -> [String: Term]? {
    fatalError("not implemented")
  }

}

/// Realizer that alternatively pulls results from multiple sub-realizers.
public final class RealizerAlternator: RealizerBase {

  init<S>(realizers: S) where S: Sequence, S.Element == Realizer {
    self.realizers = Array(realizers)
  }

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

  public func makeIterator() -> RealizerAlternator {
    return self
  }

  var index    : Int = 0
  var realizers: [Realizer]

}

/// Standard goal realizer.
public final class Realizer: RealizerBase {

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

  public override func next() -> [String: Term]? {
    // If we have a subrealizer running, pull its results first.
    if let result = subRealizer?.next() {
      return result
    } else {
      if subRealizer != nil {
        logger?.log(message: "backtacking", fontAttributes: [.dim])
        subRealizer = nil
      }
    }

    let goal = goals.first!
    logger?.log(message: "Attempting to realize ", terminator: "")
    logger?.log(message: goal.description, fontAttributes: [.bold])

    // Check for the built-in `~=~/2` predicate.
    if case ._term("lk.~=~", let args) = goal {
      assert(args.count == 2)
      if let nodeResult = unify(goal: args[0], fact: args[1]) {
        if goals.count > 1 {
          let subGoals     = goals.dropFirst().map(nodeResult.deepWalk)
          subRealizer = RealizerAlternator(realizers: [
            Realizer(
              goals         : subGoals,
              knowledge     : knowledge,
              parentBindings: nodeResult,
              logger        : logger)
            ])
          if let branchResult = subRealizer!.next() {
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
    while clauseIndex != knowledge.endIndex {
      let clause = knowledge[clauseIndex]
      clauseIndex += 1

      logger?.log(message: "using "    , terminator: "", fontAttributes: [.dim])
      logger?.log(message: "\(clause) ")

      switch (goal, clause) {
      case (.val(let lvalue), .val(let rvalue)) where lvalue == rvalue:
        if goals.count > 1 {
          let subGoals     = Array(goals.dropFirst())
          subRealizer = RealizerAlternator(realizers: [
            Realizer(goals: subGoals, knowledge: knowledge, logger: logger)
          ])
          if let branchResult = subRealizer!.next() {
            return branchResult
              .merged(with: parentBindings)
              .reified()
          }
        }

      case (._term(_, _), ._term(_, _)):
        if let nodeResult = unify(goal: goal, fact: clause) {
          if goals.count > 1 {
            let subGoals     = goals.dropFirst().map(nodeResult.deepWalk)
            subRealizer = RealizerAlternator(realizers: [
              Realizer(
                goals         : subGoals,
                knowledge     : knowledge,
                parentBindings: nodeResult,
                logger        : logger)
            ])
            if let branchResult = subRealizer!.next() {
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
        if let nodeResult = unify(goal: goal, fact: head) {
          let subGoals  = goals.dropFirst()
            .map(nodeResult.deepWalk)
          let ruleGoals = ruleBody.goals
            .map({ $0.map(nodeResult.deepWalk) + subGoals })

          // Note that we have to make sure all variables of the sub-realizer's knowldge
          // are fresh, otherwise they may collide with the ones we already bound. For
          // instance, consider a recursive rule `p(q($x), $y) ⊢ p($x, q($y))` and a
          // goal `p($z, 0)`. In this example, `$z` would get bound to `q($x)` and `$y`
          // to `0` before we try satisfy `p($x, q(0))`. But if `$x` wasn't renamed,
          // we'd be trying to unify `$x` with `q($x)` while recursing.

          subRealizer = RealizerAlternator(realizers: ruleGoals.map({
            Realizer(
              goals         : $0,
              knowledge     : knowledge.refreshed,
              parentBindings: nodeResult,
              logger        : logger)
          }))
          if let branchResult = subRealizer!.next() {
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

  let goals         : [Term]
  let knowledge     : KnowledgeBase
  let parentBindings: BindingMap
  var logger        : Logger?

  var clauseIndex   : Int = 0
  var subRealizer   : RealizerAlternator? = nil

}
