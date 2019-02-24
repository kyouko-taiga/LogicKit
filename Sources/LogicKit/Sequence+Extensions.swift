extension Sequence {

  func concatenated<S>(with other: S) -> SequenceConcatenation<Self, S>
    where S: Sequence, S.Element == Element
  {
    return SequenceConcatenation(self, other)
  }

}

struct SequenceConcatenation<S1, S2>: Sequence
  where S1: Sequence, S2: Sequence, S1.Element == S2.Element
{

  init(_ first: S1, _ second: S2) {
    self.first = first
    self.second = second
  }

  func makeIterator() -> AnyIterator<S1.Element> {
    var iter1 = first.makeIterator()
    var iter2 = second.makeIterator()
    return AnyIterator {
      return iter1.next() ?? iter2.next()
    }
  }

  private let first: S1
  private let second: S2

}
