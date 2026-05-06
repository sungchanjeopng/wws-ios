import XCTest
@testable import WWS2Core

final class InterfaceDiagReadingTests: XCTestCase {
    func testFromBytesParses22BytePayload() throws {
        let payload: [UInt8] = [
            0x01, 0x3B, // 31.5 C
            0x01, 0xC8, // 4.56 mA
            0x00, 0x02, // freq index
            0xFF, 0x83, // -1.25 offset
            0x01, 0x90, // 4.00 mA
            0x07, 0xD0, // 20.00 mA
            0x00, 0x37, // tvg
            0x00, 0x06, // damp
            0x00, 0x03, // asf
            0x00, 0x00, // relay on
            0x00, 0x09, // errorCode
        ]

        let reading = try XCTUnwrap(InterfaceDiagReading.fromBytes(payload))
        XCTAssertEqual(reading.temperature, 31.5, accuracy: 0.0001)
        XCTAssertEqual(reading.currentMA, 4.56, accuracy: 0.0001)
        XCTAssertEqual(reading.freq, 2)
        XCTAssertEqual(reading.freqLabel, "270K")
        XCTAssertEqual(reading.offset, -1.25, accuracy: 0.0001)
        XCTAssertEqual(reading.set4mA, 4.0, accuracy: 0.0001)
        XCTAssertEqual(reading.set20mA, 20.0, accuracy: 0.0001)
        XCTAssertEqual(reading.tvg, 55)
        XCTAssertEqual(reading.damp, 6)
        XCTAssertEqual(reading.asf, 3)
        XCTAssertTrue(reading.relayOn)
        XCTAssertEqual(reading.errorCode, 9)
    }
}
