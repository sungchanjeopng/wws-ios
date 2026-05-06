import XCTest
@testable import WWS2Core

final class DiagReadingTests: XCTestCase {
    func testFromBytesParses16BytePayload() throws {
        let payload: [UInt8] = [
            0x01, 0x00, // 25.6 C
            0x04, 0xD2, // 12.34 mA
            0x00, 0x1E, // damping 30
            0x01, 0x90, // 4.00 mA
            0x07, 0xD0, // 20.00 mA
            0x00, 0x02, // pipeDia
            0x01, 0x7C, // 0.380 MHz
            0x00, 0x07, // errorCode
        ]

        let reading = try XCTUnwrap(DiagReading.fromBytes(payload))
        XCTAssertEqual(reading.temperature, 25.6, accuracy: 0.0001)
        XCTAssertEqual(reading.currentMA, 12.34, accuracy: 0.0001)
        XCTAssertEqual(reading.damping, 30)
        XCTAssertEqual(reading.set4mA, 4.0, accuracy: 0.0001)
        XCTAssertEqual(reading.set20mA, 20.0, accuracy: 0.0001)
        XCTAssertEqual(reading.pipeDia, 2)
        XCTAssertEqual(reading.freqMHz, 0.380, accuracy: 0.0001)
        XCTAssertEqual(reading.errorCode, 7)
    }
}
