public struct KnowledgeBase {

    public init(knowledge: [Term]) {
        self.knowledge = knowledge
    }

    public func ask(_ query: Term, logger: Logger? = nil) -> RealizerAlternator {
        switch query {
        case .var(_), ._rule(_, _, _):
            preconditionFailure("invalid query")
        default:
            return RealizerAlternator(realizers: query.goals.map({
                Realizer(goals: $0, knowledge: self.refreshed, logger: logger)
            }))
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
        return KnowledgeBase(knowledge: self.knowledge.map(self.renameVariables))
    }

    func renameVariables(of term: Term) -> Term {
        switch term {
        case .var(let name):
            return .var(name + "'")
        case ._term(let name, let arguments):
            return ._term(name: name, arguments: arguments.map(self.renameVariables))
        case ._rule(let name, let arguments, let body):
            return ._rule(
                name     : name,
                arguments: arguments.map(self.renameVariables),
                body     : self.renameVariables(of: body))
        case .conjunction(let lhs, let rhs):
            return .conjunction(self.renameVariables(of: lhs), self.renameVariables(of: rhs))
        case .disjunction(let lhs, let rhs):
            return .disjunction(self.renameVariables(of: lhs), self.renameVariables(of: rhs))
        default:
            return term
        }
    }

    public let knowledge: [Term]

}

extension KnowledgeBase: Hashable {

    public var hashValue: Int {
        return hash(self.knowledge.map({ $0.hashValue }))
    }

    public static func ==(lhs: KnowledgeBase, rhs: KnowledgeBase) -> Bool {
        return lhs.knowledge == rhs.knowledge
    }

}

extension KnowledgeBase: Collection {

    public typealias Element = Term

    public var startIndex: Int {
        return self.knowledge.startIndex
    }

    public var endIndex: Int {
        return self.knowledge.endIndex
    }

    public func index(after i: Int) -> Int {
        return self.knowledge.index(after: i)
    }

    public func makeIterator() -> Array<Term>.Iterator {
        return self.knowledge.makeIterator()
    }

    public subscript(position: Int) -> Term {
        return self.knowledge[position]
    }

}

extension KnowledgeBase: ExpressibleByArrayLiteral {

    public init(arrayLiteral knowledge: Term...) {
        self.init(knowledge: knowledge)
    }

}

extension KnowledgeBase: CustomStringConvertible {

    public var description: String {
        return self.knowledge.description
    }

}
