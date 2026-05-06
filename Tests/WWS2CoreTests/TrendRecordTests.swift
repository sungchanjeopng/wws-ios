import XCTest
@testable import WWS2Core

final class TrendRecordTests: XCTestCase {
    func testFromBytesParses24BytePayload() throws {
        let payload: [UInt8] = [
            0x00, 0x18, // year 2024
            0x00, 0x05, // month 5
            0x00, 0x1A, // day 26
            0x00, 0x0E, // hour 14
            0x00, 0x1E, // minute 30
            0x00, 0x2D, // second 45
            0x01, 0xF4, // eeaD 500
            0x27, 0x10, // dst 10000
            0x00, 0xFD, // 25.3 C
            0x00, 0x0A, // step 10
            0x00, 0x14, // vca 20
            0x00, 0x02, // status 2
        ]

        let record = try XCTUnwrap(TrendRecord.fromBytes(payload))
        XCTAssertEqual(record.dateTime.year, 2024)
        XCTAssertEqual(record.dateTime.month, 5)
        XCTAssertEqual(record.dateTime.day, 26)
        XCTAssertEqual(record.dateTime.hour, 14)
        XCTAssertEqual(record.dateTime.minute, 30)
        XCTAssertEqual(record.dateTime.second, 45)
        XCTAssertEqual(record.eeaD, 500)
        XCTAssertEqual(record.dst, 10000)
        XCTAssertEqual(record.temperature, 25.3, accuracy: 0.0001)
        XCTAssertEqual(record.step, 10)
        XCTAssertEqual(record.vca, 20)
        XCTAssertEqual(record.status, 2)
    }
}
