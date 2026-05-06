import XCTest
@testable import WWS2Core

final class CrcFrameTests: XCTestCase {
    func testCrcKnownVectors() {
        let bytes = Array("123456789".utf8)
        XCTAssertEqual(Crc.crc16Modbus(bytes), 0x4B37)
        XCTAssertEqual(Crc.crc32(bytes), 0xCBF43926)
    }

    func testDeviceInfoRequestHasValidCrc() {
        let frame = FrameCodec.buildDeviceInfoRequest(pin: 1234)
        XCTAssertEqual(frame[0], 0x02)
        XCTAssertEqual(frame.count, 7)
        XCTAssertNotNil(FrameCodec.parseFrame(frame))
        let parsed = FrameCodec.parseFrame(frame)
        XCTAssertEqual(parsed?.cmd, Command.deviceInfo)
        XCTAssertEqual(parsed?.data, [0x04, 0xD2])
    }

    func testHeartbeatRoundtrip() {
        let f = FrameCodec.buildHeartbeat(pageIndex: Command.pageStatus, expectedLen: 34)
        let p = FrameCodec.parseFrame(f)
        XCTAssertEqual(p?.cmd, Command.pageStatus)
        XCTAssertEqual(p?.data, [0x00, 0x22])
    }

    func testBadCrcRejected() {
        var f = FrameCodec.buildHeartbeat(pageIndex: Command.pageTrend)
        f[f.count - 1] ^= 0xFF
        XCTAssertNil(FrameCodec.parseFrame(f))
    }
}
