public struct KnowledgeBase {

  public init(knowledge: [Term]) {
    self.knowledge = knowledge
  }

  public func ask(_ query: Term, logger: Logger? = nil) -> AnswerSet {
    switch query {
    case .var, ._rule:
      preconditionFailure("invalid query")

    default:
      // Build an array of realizers for each conjunction of goals in the query.
      let realizers = query.goals.map {
        Realizer(goals: $0, knowledge: refreshed, logger: logger)
      }

      // Return the goal realizer(s).
      assert(!realizers.isEmpty)
      let iterator = realizers.count > 1
        ? RealizerAlternator(realizers: realizers)
        : realizers[0]
      return AnswerSet(realizer: iterator, variables: query.variables)
    }
  }

  public func union(with other: KnowledgeBase) -> KnowledgeBase {
    var newClauses = self.knowledge
    for clause in other.knowledge {
      if !newClauses.contains(clause) {
        newClauses.append(clause)
      }
    }
    return KnowledgeBase(knowledge: newClauses)
  }

  var refreshed: KnowledgeBase {
    return KnowledgeBase(knowledge: knowledge.map(renameVariables))
  }

  func renameVariables(of term: Term) -> Term {
    switch term {
    case .var(let name):
      return .var(name + "'")
    case ._term(let name, let arguments):
      return ._term(name: name, arguments: arguments.map(renameVariables))
    case ._rule(let name, let arguments, let body):
      return ._rule(
        name     : name,
        arguments: arguments.map(renameVariables),
        body     : renameVariables(of: body))
    case .conjunction(let lhs, let rhs):
      return .conjunction(renameVariables(of: lhs), renameVariables(of: rhs))
    case .disjunction(let lhs, let rhs):
      return .disjunction(renameVariables(of: lhs), renameVariables(of: rhs))
    default:
      return term
    }
  }

  public let knowledge: [Term]

}

extension KnowledgeBase: Hashable {
}

extension KnowledgeBase: Collection {

  public typealias Element = Term

  public var startIndex: Int {
    return knowledge.startIndex
  }

  public var endIndex: Int {
    return knowledge.endIndex
  }

  public func index(after i: Int) -> Int {
    return knowledge.index(after: i)
  }

  public func makeIterator() -> Array<Term>.Iterator {
    return knowledge.makeIterator()
  }

  public subscript(position: Int) -> Term {
    return knowledge[position]
  }

}

extension KnowledgeBase: ExpressibleByArrayLiteral {

  public init(arrayLiteral knowledge: Term...) {
    self.init(knowledge: knowledge)
  }

}

extension KnowledgeBase: CustomStringConvertible {

  public var description: String {
    return knowledge.description
  }

}
