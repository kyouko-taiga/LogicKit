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

  func log(message: String, terminator: String, fontAttributes: [FontAttribute])

}

extension Logger {

  public func log(message: String) {
    self.log(message: message, terminator: "\n", fontAttributes: [])
  }

  public func log(message: String, fontAttributes: [FontAttribute]) {
    self.log(message: message, terminator: "\n", fontAttributes: fontAttributes)
  }

  public func log(message: String, terminator: String) {
    self.log(message: message, terminator: terminator, fontAttributes: [])
  }

}

public struct DefaultLogger: Logger {

  public init() {}

  public func log(message: String, terminator: String, fontAttributes: [FontAttribute]) {
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
