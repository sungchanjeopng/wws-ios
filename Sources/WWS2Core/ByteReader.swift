import Foundation

public struct ByteReader {
    public let data: [UInt8]
    private(set) public var offset: Int = 0

    public init(_ data: [UInt8]) { self.data = data }
    public init(_ data: Data) { self.data = Array(data) }

    public var remaining: Int { data.count - offset }

    public mutating func readUInt8() -> UInt8? {
        guard offset < data.count else { return nil }
        defer { offset += 1 }
        return data[offset]
    }

    public mutating func readUInt16BE() -> UInt16? {
        guard offset + 1 < data.count else { return nil }
        let v = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        return v
    }

    public mutating func readInt16BE() -> Int16? {
        guard let u: UInt16 = readUInt16BE() else { return nil }
        return Int16(bitPattern: u)
    }

    public mutating func readUInt32LE() -> UInt32? {
        guard offset + 3 < data.count else { return nil }
        let v = UInt32(data[offset]) | (UInt32(data[offset + 1]) << 8) | (UInt32(data[offset + 2]) << 16) | (UInt32(data[offset + 3]) << 24)
        offset += 4
        return v
    }
}

public extension Array where Element == UInt8 {
    func hexString(separator: String = " ") -> String {
        map { String(format: "%02X", $0) }.joined(separator: separator)
    }
}

public extension Data {
    var bytes: [UInt8] { Array(self) }
}
