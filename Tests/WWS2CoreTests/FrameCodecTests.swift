import XCTest
@testable import WWS2Core

final class FrameCodecTests: XCTestCase {
    func testHeartbeatRoundTrip() {
        let frame = FrameCodec.buildHeartbeat(pageIndex: Command.pageStatus, expectedLen: 0x001A)
        let parsed = FrameCodec.parseFrame(frame)

        XCTAssertEqual(parsed?.cmd, Command.pageStatus)
        XCTAssertEqual(parsed?.data, [0x00, 0x1A])
    }

    func testDeviceInfoRequestIsValidFrame() {
        let frame = FrameCodec.buildDeviceInfoRequest(pin: 1234)
        let parsed = FrameCodec.parseFrame(frame)

        XCTAssertEqual(parsed?.cmd, Command.deviceInfo)
        XCTAssertEqual(parsed?.data, [0x04, 0xD2])
    }

    func testParseDensityDeviceInfoResponse() {
        let frame = makeRawFrame(cmd: Command.deviceInfo, payload: [0x41, 0x01, 0x01, 0x02, 0x03])

        guard case let .success(info)? = FrameCodec.parsePairingResponse(frame) else {
            return XCTFail("expected success device info")
        }

        XCTAssertEqual(info.siteName, "A01")
        XCTAssertEqual(info.ch2SiteName, "")
        XCTAssertEqual(info.fwVersion, FwVersion(1, 2, 3))
    }

    func testParseInterfaceDeviceInfoResponse() {
        let frame = makeRawFrame(cmd: Command.deviceInfo, payload: [0x41, 0x01, 0x42, 0x02, 0x01, 0x02, 0x03])

        guard case let .success(info)? = FrameCodec.parsePairingResponse(frame) else {
            return XCTFail("expected success device info")
        }

        XCTAssertEqual(info.siteName, "A01")
        XCTAssertEqual(info.ch2SiteName, "B02")
        XCTAssertTrue(info.isDualChannel)
        XCTAssertEqual(info.fwVersion.description, "v1.2.3")
    }

    func testParsePinFailurePairingResponse() {
        let frame = makeRawFrame(cmd: Command.deviceInfo, payload: [0x00, 0x01])

        guard case .pinFailed? = FrameCodec.parsePairingResponse(frame) else {
            return XCTFail("expected pinFailed")
        }
    }

    func testRejectsBadCrc() {
        var frame = FrameCodec.buildHeartbeat(pageIndex: Command.pageStatus)
        frame[frame.count - 1] ^= 0xFF

        XCTAssertNil(FrameCodec.parseFrame(frame))
        XCTAssertNil(FrameCodec.parsePairingResponse(frame))
    }

    func testU32LittleEndianHelper() {
        XCTAssertEqual(FrameCodec.u32le(0x12345678), [0x78, 0x56, 0x34, 0x12])
    }

    func testIndexOfSubsequence() {
        XCTAssertEqual(FrameCodec.indexOfSubsequence(data: [1, 2, 3, 4, 5], pattern: [3, 4]), 2)
        XCTAssertNil(FrameCodec.indexOfSubsequence(data: [1, 2, 3], pattern: [4]))
    }

    private func makeRawFrame(cmd: Int, payload: [UInt8]) -> [UInt8] {
        var frame: [UInt8] = [
            FrameCodec.sof,
            UInt8((cmd >> 8) & 0xFF),
            UInt8(cmd & 0xFF),
        ]
        frame.append(contentsOf: payload)
        let crc = Crc.crc16Modbus(frame)
        frame.append(UInt8(crc & 0xFF))
        frame.append(UInt8((crc >> 8) & 0xFF))
        return frame
    }
}
