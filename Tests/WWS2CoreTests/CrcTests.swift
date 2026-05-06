import XCTest
@testable import WWS2Core

final class CrcTests: XCTestCase {
    func testCrc16ModbusKnownVector() {
        let bytes = Array("123456789".utf8)
        XCTAssertEqual(Crc.crc16Modbus(bytes), 0x4B37)
    }

    func testCrc16IncrementalUpdateMatchesWholeBuffer() {
        let bytes = Array("WESSWARE".utf8)
        let whole = Crc.crc16Modbus(bytes)
        let incremental = bytes.reduce(UInt16(0xFFFF)) { partial, byte in
            Crc.crc16Update(partial, byte: byte)
        }

        XCTAssertEqual(incremental, whole)
    }

    func testCrc32KnownVector() {
        let bytes = Array("123456789".utf8)
        XCTAssertEqual(Crc.crc32(bytes), 0xCBF43926)
    }
}
