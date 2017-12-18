public typealias BindingMap = Dictionary<String, Term>

extension Dictionary where Key == String, Value == Term {

    func reified() -> [String: Term] {
        var result: [String: Term] = [:]
        for (name, term) in self {
            result[name] = self.deepWalk(term)
        }
        return result
    }

    func shallowWalk(_ term: Term) -> Term {
        switch term {
        case .var(let name):
            return self[name].map({
                self.shallowWalk($0)
            }) ?? term
        default:
            return term
        }
    }

    func deepWalk(_ term: Term) -> Term {
        let walked = self.shallowWalk(term)
        switch walked {
        case ._term(name: let name, arguments: let arguments):
            return ._term(name: name, arguments: arguments.map(self.deepWalk))
        case .conjunction(let lhs, let rhs):
            return .conjunction(self.deepWalk(lhs), self.deepWalk(rhs))
        case .disjunction(let lhs, let rhs):
            return .disjunction(self.deepWalk(lhs), self.deepWalk(rhs))
        default:
            return walked
        }
    }

    func binding(_ name: String, to term: Term) -> Dictionary {
        var result = self
        result[name] = term
        return result
    }

    func merged(with other: Dictionary) -> Dictionary {
        var result = self
        for (name, term) in other {
            result[name] = term
        }
        return result
    }

}
