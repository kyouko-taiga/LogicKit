import LogicKit
import Parsey

public struct Grammar {

    // MARK: Knowledge base (entry point of the grammar)

    public static let knowledge = newlines.? ~~> statement.*
    public static let statement = (term | rule).amid(ws.?) <~~ terminator

    public static let terminator =
        (comma.amid(ws.?) <~~ newlines).skipped()
        | newlines.skipped()
        | Lexer.end.skipped()

    // MARK: Variables

    public static let variable =
        ".var(" ~~> string.amid(ws.?) <~~ ")"
        <!-- "a variable"
        ^^ { Term.var($0) }

    // MARK: Literals

    public static let literal =
        ".lit(" ~~> (intLiteral | boolLiteral | strLiteral).amid(ws.?) <~~ ")"

    public static let intLiteral =
        Lexer.signedInteger <!-- "an integer literal"
        ^^ { Term.lit(Int($0)!) }

    public static let boolLiteral =
        (Lexer.regex("true") | Lexer.regex("false")) <!-- "a bool literal"
        ^^ { Term.lit($0 == "true") }

    public static let strLiteral =
        string <!-- "a string literal"
        ^^ { Term.lit($0) }

    // MARK: Terms

    public static let term = disjunction

    public static let disjunction = conjunction.amid(ws.?).infixedLeft(by: orOperator)
    public static let orOperator  =
        Lexer.regex("\\|\\|").amid(newlines.?)
        <!-- "an or operator"
        ^^ { op in { Term.disjunction($0, $1) } }

    public static let conjunction = atom.amid(ws.?).infixedLeft(by: andOperator)
    public static let andOperator =
        Lexer.regex("&&").amid(newlines.?)
        <!-- "an and operator"
        ^^ { op in { Term.conjunction($0, $1) } }

    public static let atom = variable | literal | fact

    public static let fact: Parser<Term> =
        ".fact(" ~~> string.amid(ws.?) ~~ (comma ~~> arguments).? <~~ ")"
        <!-- "a fact"
        ^^ { val in ._term(name: val.0, arguments: val.1 ?? []) }

    public static let arguments =
        (variable | literal | fact).many(separatedBy: comma) <~~ ws.?
        <!-- "a subterm"

    // MARK: Rules

    public static let rule: Parser<Term> =
        (".rule(" ~~> string.amid(ws.?) ~~ (comma ~~> arguments).? <~~ ")") ~~
        (lbrace ~~> term.amid(ws.?).amid(newlines.?) <~~ rbrace)
        //(lbrace ~~> term.amid(ws.?) <~~ rbrace)
        ^^ { val in ._rule(name: val.0.0, arguments: val.0.1 ?? [], body: val.1) }

    public static let lbrace = Lexer.character("{").amid(ws.?)
    public static let rbrace = Lexer.character("}").amid(ws.?)

    // MARK: Other terminal symbols

    public static let string =
        Lexer.regex("\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"")
        ^^ { $0[1 ..< ($0.count - 1)] }

    public static let comment  = Lexer.regex("\\//[^\\n]*")
    public static let ws       = Lexer.whitespaces
    public static let newlines = (Lexer.newLine | ws.? ~~> comment).+
    public static let comma    = Lexer.character(",").amid(ws.?)

}

extension String {

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end   = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ..< end])
    }

}
