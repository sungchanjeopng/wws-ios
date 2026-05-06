import Foundation

public struct ByteReader: Sendable {
    public let bytes: [UInt8]
    public private(set) var offset: Int = 0

    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }

    public var remaining: Int { bytes.count - offset }

    public mutating func readUInt8() -> UInt8? {
        guard remaining >= 1 else { return nil }
        let value = bytes[offset]
        offset += 1
        return value
    }

    public mutating func readUInt16BE() -> UInt16? {
        guard remaining >= 2 else { return nil }
        let v = (UInt16(bytes[offset]) << 8) | UInt16(bytes[offset + 1])
        offset += 2
        return v
    }

    public mutating func readInt16BE() -> Int16? {
        guard let u = readUInt16BE() else { return nil }
        return Int16(bitPattern: u)
    }

    public mutating func readBytes(_ count: Int) -> [UInt8]? {
        guard remaining >= count else { return nil }
        let out = Array(bytes[offset..<offset + count])
        offset += count
        return out
    }

    @discardableResult
    public mutating func skip(_ count: Int) -> Bool {
        guard remaining >= count else { return false }
        offset += count
        return true
    }
}
