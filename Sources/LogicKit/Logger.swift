public enum FontColor {

  case red, green, yellow

}

public enum FontAttribute {

  case bold
  case dim
  case foreground(FontColor)
  case background(FontColor)

}

public protocol Logger {

  func didBacktrack()
  func willRealize(goal: Term)
  func willAttempt(clause: Term)

}

public struct DefaultLogger: Logger {

  public init(useFontAttributes: Bool = true) {
    self.useFontAttributes = useFontAttributes
  }

  public let useFontAttributes: Bool

  public func didBacktrack() {
    log(message: "backtacking", fontAttributes: [.dim])
  }

  public func willRealize(goal: Term) {
    log(message: "Attempting to realize ", terminator: "")
    log(message: "\(goal)", fontAttributes: [.bold])
  }

  public func willAttempt(clause: Term) {
    log(message: "using "    , terminator: "", fontAttributes: [.dim])
    log(message: "\(clause) ")
  }

  public func log(message: String, terminator: String, fontAttributes: [FontAttribute]) {
    if useFontAttributes {
      let attributes = fontAttributes.compactMap({
        switch $0 {
        case .bold:
          return "\u{001B}[1m"
        case .dim:
          return "\u{001B}[2m"
        case .foreground(let color):
          return "\u{001B}[\(DefaultLogger.foreground[color] ?? "39m")"
        case .background(let color):
          return "\u{001B}[\(DefaultLogger.background[color] ?? "40m")"
        }
      }).joined(separator: "")
      print("\(attributes)\(message)\u{001B}[0m", terminator: terminator)
    } else {
      print(message, terminator: terminator)
    }
  }

  public func log(message: String) {
    log(message: message, terminator: "\n", fontAttributes: [])
  }

  public func log(message: String, fontAttributes: [FontAttribute]) {
    log(message: message, terminator: "\n", fontAttributes: fontAttributes)
  }

  public func log(message: String, terminator: String) {
    log(message: message, terminator: terminator, fontAttributes: [])
  }

  static let foreground: [FontColor: String] = [
    .red   : "31m",
    .green : "32m",
    .yellow: "33m",
  ]

  static let background: [FontColor: String] = [
    .red   : "41m",
    .green : "42m",
    .yellow: "43m",
  ]

}
