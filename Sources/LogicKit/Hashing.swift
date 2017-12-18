#if arch(x86_64) || arch(arm64)
    let FNV_OFFSET_BASIS = Int(bitPattern: 0xcbf29ce484222325)
    let FNV_PRIME        = Int(bitPattern: 0x100000001b3)
#elseif arch(i386) || arch(arm)
    let FNV_OFFSET_BASIS = Int(bitPattern: 0x811c9dc5)
    let FNV_PRIME        = Int(bitPattern: 0x1000193)
#endif

/// Fowler–Noll–Vo hash function implementation.
public func fnv1(data: UnsafeRawPointer, size: Int) -> Int {
    var h = FNV_OFFSET_BASIS
    for i in 0 ..< size {
        h = h &* FNV_PRIME
        h = h ^ Int(data.load(fromByteOffset: i, as: UInt8.self))
    }
    return h
}

/// Fowler–Noll–Vo hash function implementation.
public func fnv1(_ n: Int) -> Int {
    var h = FNV_OFFSET_BASIS
    for i in 0 ..< MemoryLayout<Int>.size {
        h = h &* FNV_PRIME
        h = h ^ Int(UInt8(truncatingIfNeeded: n >> (8 * i)))
    }
    return h
}

/// Hashes a sequence of integers.
public func hash<S>(_ sequence: S) -> Int where S: Sequence, S.Element == Int {
    let data = Array(sequence)
    return data.withUnsafeBufferPointer { buffer in
        return fnv1(
            data: UnsafeRawPointer(buffer.baseAddress)!,
            size: MemoryLayout<S.Element>.size * data.count)
    }
}
