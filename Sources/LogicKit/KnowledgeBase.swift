public struct KnowledgeBase: Hashable {

  public init(predicates: [String: [Term]], literals: Set<Term>) {
    let terms = predicates.values.joined().concatenated(with: literals)
    for term in terms {
      switch term {
      case ._term, ._rule:
        continue
      default:
        fatalError("Cannot use '\(term)' as a predicate.")
      }
    }

    self.predicates = predicates
    self.literals = literals
  }

  public init(knowledge: [Term]) {
    /// Extract predicates and literals from the given list of terms.
    for term in knowledge {
      switch term {
      case ._term(let name, _):
        let group = predicates[name] ?? []
        predicates[name] = group + [term]

      case ._rule(let name, _, _):
        let group = predicates[name] ?? []
        predicates[name] = group + [term]

      case .val:
        literals.insert(term)

      case .var, .conjunction, .disjunction:
        fatalError("Cannot use '\(term)' as a predicate.")
      }
    }
  }

  /// The list of predicates in the knowledge base, grouped by functor.
  public private(set) var predicates: [String: [Term]] = [:]
  /// The list of isolated literals in the knowledge base.
  public private(set) var literals: Set<Term> = []

  /// The number of predicates and literals in the knowledge base.
  public var count: Int { return predicates.values.reduce(0, { $0 + $1.count }) + literals.count }

  public func ask(_ query: Term, logger: Logger? = nil) -> AnswerSet {
    switch query {
    case .var, ._rule:
      fatalError("invalid query")

    default:
      // Build an array of realizers for each conjunction of goals in the query.
      let realizers = query.goals.map {
        Realizer(goals: $0, knowledge: renaming(query.variables), logger: logger)
      }

      // Return the goal realizer(s).
      assert(!realizers.isEmpty)
      let iterator = realizers.count > 1
        ? RealizerAlternator(realizers: realizers)
        : realizers[0]
      return AnswerSet(realizer: iterator, variables: query.variables)
    }
  }

  func renaming(_ variables: Set<String>) -> KnowledgeBase {
    var result = KnowledgeBase(knowledge: [])
    for (name, terms) in predicates {
      result.predicates[name] = terms.map { $0.renaming(variables) }
    }
    result.literals = literals
    return result
  }

  func renameVariables(of term: Term) -> Term {
    switch term {
    case .var(let name):
      return .var(name + "'")
    case ._term(let name, let args):
      return ._term(name: name, arguments: args.map(renameVariables))
    case ._rule(let name, let args, let body):
      return ._rule(
        name: name,
        arguments: args.map(renameVariables),
        body: renameVariables(of: body))
    case .conjunction(let lhs, let rhs):
      return .conjunction(renameVariables(of: lhs), renameVariables(of: rhs))
    case .disjunction(let lhs, let rhs):
      return .disjunction(renameVariables(of: lhs), renameVariables(of: rhs))
    default:
      return term
    }
  }

  public static func + (lhs: KnowledgeBase, rhs: KnowledgeBase) -> KnowledgeBase {
    var result = KnowledgeBase(knowledge: [])
    for (name, terms) in lhs.predicates {
      result.predicates[name] = terms
      if let right = rhs.predicates[name] {
        result.predicates[name]!.append(contentsOf: right)
      }
    }
    result.literals = lhs.literals.union(rhs.literals)
    return result
  }

}

extension KnowledgeBase: Sequence {

  public typealias Element = Term

  public func makeIterator() -> AnyIterator<Element> {
    return predicates.values.joined().concatenated(with: literals).makeIterator()
  }

}

extension KnowledgeBase: ExpressibleByArrayLiteral {

  public init(arrayLiteral knowledge: Term...) {
    self.init(knowledge: knowledge)
  }

}

extension KnowledgeBase: CustomStringConvertible {

  public var description: String {
    return "[" + self.map({ "\($0)" }).joined(separator: ", ") + "]"
  }

}
