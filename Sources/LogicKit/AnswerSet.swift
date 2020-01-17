public struct AnswerSet: IteratorProtocol, Sequence {

  init(realizer: RealizerBase, variables: Set<String>) {
    self.realizer = realizer
    self.variables = variables
  }

  private var realizer: RealizerBase
  private var variables: Set<String>

  public func next() -> BindingMap? {
    return realizer.next()?.reified.filter { variables.contains($0.key) }
  }

  public var all: [BindingMap] { Array(self) }

}
