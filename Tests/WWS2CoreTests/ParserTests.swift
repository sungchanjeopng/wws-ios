import XCTest
@testable import WWS2Core

final class ParserTests: XCTestCase {
    func testStatus4B() {
        let data: [UInt8] = [0x01, 0xF4, 0x00, 0x02] // 500 => 5.00m, ER02
        let result = FrameParser.parse(cmd: Command.status, data: data, isInterface: false)
        guard case .status4B(let reading) = result else { return XCTFail("wrong result") }
        XCTAssertEqual(reading.level, 5.0, accuracy: 0.0001)
        XCTAssertEqual(reading.errorCode, 2)
    }

    func testDeviceReading16B() {
        let data: [UInt8] = [0x00,0x64, 0x00,0xFA, 0x01,0x2C, 0x00,0x05, 0x00,0xC8, 0x03,0xE8, 0x00,0x01, 0x01,0x86]
        let r = DeviceReading.fromBytes(data)
        XCTAssertEqual(r?.level, 100)
        XCTAssertEqual(r?.temperature, 25.0, accuracy: 0.001)
        XCTAssertEqual(r?.currentMA, 3.0, accuracy: 0.001)
    }

    func testTrendRecord24B() {
        let data: [UInt8] = [0,26,0,5,0,4,0,12,0,34,0,56, 0x01,0x02, 0x03,0xE8, 0x00,0xFA, 0x00,0x02, 0x00,0x03, 0x00,0x04]
        let rec = TrendRecord.fromBytes(data)
        XCTAssertNotNil(rec)
        XCTAssertEqual(rec?.eeaD, 0x0102)
        XCTAssertEqual(rec?.dst, 1000)
        XCTAssertEqual(rec?.temperature, 25.0, accuracy: 0.001)
    }
}
