#if os(Linux)
    import Glibc
#else
    import Darwin
#endif
import linenoise
import LogicKit
import LogicKitParser

let bulbasaur : Term = .lit("Bulbasaur")
let squirtle  : Term = .lit("Squirtle")
let charmander: Term = .lit("Charmander")

func makeCString(from string: String) -> UnsafeMutablePointer<Int8>? {
    return string.withCString {
        let len = Int(strlen($0) - 1)
        return strcpy(UnsafeMutablePointer<Int8>.allocate(capacity: len), $0)
    }
}

let logger = DefaultLogger()

guard CommandLine.argc > 1 else {
    logger.log(message: "error: ", terminator: "", fontAttributes: [.foreground(.red)])
    logger.log(message: "no input file")
    fatalError()
}

let path = CommandLine.arguments[1]
guard let fp = fopen(path, "r") else {
    logger.log(message: "error: ", terminator: "", fontAttributes: [.foreground(.red)])
    logger.log(message: "could not read '\(path)'")
    fatalError()
}

var source = ""
var buffer = [CChar](repeating: 0, count: 1024)
var n = 1024
while fgets(&buffer, 1025, fp) != nil {
    source += String(cString: buffer)
}
fclose(fp)

let knowledgeBase: KnowledgeBase
do {
    knowledgeBase = KnowledgeBase(knowledge: try Grammar.knowledge.parse(source))
} catch let e {
    logger.log(message: "error: ", terminator: "", fontAttributes: [.foreground(.red)])
    logger.log(message: "invalid input")
    logger.log(message: "\(e)")
    fatalError()
}

linenoiseHistorySetMaxLen(50)

linenoiseSetCompletionCallback { buf, completions in
    guard buf != nil else { return }
    let input = String(cString: buf!)

    for command in [".var", ".lit", ".fact", ".rule"] {
        var i = command.index(before: command.endIndex)
        let s = command.index(after : command.startIndex)

        while i > s {
            if input.hasSuffix(String(command[command.startIndex ..< i])) {
                linenoiseAddCompletion(
                    completions, input + String(command[i ..< command.endIndex]))
                return
            }
            i = command.index(before: i)
        }
    }
}

linenoiseSetHintsCallback { (buf, color, bold) -> UnsafeMutablePointer<Int8>? in
    guard buf != nil else { return nil }
    let input = String(cString: buf!)

    bold?.pointee  = 2

    if input.hasSuffix(".var") {
        return makeCString(from: "(<name>)")
    } else if input.hasSuffix(".lit") {
        return makeCString(from: "(<literal>)")
    } else if input.hasSuffix(".fact") {
        return makeCString(from: "(<name>, <arg0>, <arg1>, ...)")
    } else if input.hasSuffix(".rule") {
        return makeCString(from: "(<name>, <arg0>, <arg1>, ...) { <goal> }")
    }

    return nil
}

linenoiseSetFreeHintsCallback {
    let cString = $0!.assumingMemoryBound(to: Int8.self)
    cString.deallocate(capacity: strlen(cString) - 1)
}

while true {
    guard let buf = linenoise("?- ") else { break }
    linenoiseHistoryAdd(buf)
    let q = String(cString: buf)

    var response: RealizerAlternator? = nil
    do {
        let query = try Grammar.atom.parse(q)
        response = knowledgeBase.ask(query, logger: logger)
    } catch let e {
        logger.log(message: "error: ", terminator: "", fontAttributes: [.foreground(.red)])
        logger.log(message: "invalid query '\(q)'")
        logger.log(message: "\(e)")
    }

    guard response != nil else { continue }
    while let result = response!.next() {
        for (variable, term) in result {
            logger.log(message: "  \(variable) ↦ \(term)", fontAttributes: [.bold])
        }
        print("continue [y/n]? ", terminator: "")
        if let command = readLine() {
            if command == "y" { continue } else { break }
        }
    }
    logger.log(message: "no result")
}
