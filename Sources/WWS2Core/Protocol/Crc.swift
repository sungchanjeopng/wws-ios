import Foundation

public enum Crc {
    public static func crc16Modbus(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for b in bytes {
            crc ^= UInt16(b)
            for _ in 0..<8 {
                if (crc & 0x0001) != 0 {
                    crc = (crc >> 1) ^ 0xA001
                } else {
                    crc >>= 1
                }
            }
        }
        return crc
    }

    public static func crc16Update(_ crc: UInt16, byte: UInt8) -> UInt16 {
        var c = crc ^ UInt16(byte)
        for _ in 0..<8 {
            c = (c & 0x0001) != 0 ? ((c >> 1) ^ 0xA001) : (c >> 1)
        }
        return c
    }

    public static func crc32(_ bytes: [UInt8]) -> UInt32 {
        let poly: UInt32 = 0xEDB88320
        var table = [UInt32](repeating: 0, count: 256)
        for i in 0..<256 {
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (poly ^ (c >> 1)) : (c >> 1)
            }
            table[i] = c
        }
        var crc: UInt32 = 0xFFFFFFFF
        for b in bytes {
            let idx = Int((crc ^ UInt32(b)) & 0xFF)
            crc = table[idx] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}
