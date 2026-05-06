import XCTest
@testable import WWS2BLE
import WWS2Core

final class ProtocolClientTests: XCTestCase {
    func testBuildPairingRequestMatchesCoreFrameCodec() {
        let client = ProtocolClient()
        XCTAssertEqual(client.buildPairingRequest(pin: 1234), FrameCodec.buildDeviceInfoRequest(pin: 1234))
    }

    func testBuildHeartbeatRequestMatchesCoreFrameCodec() {
        let client = ProtocolClient(isInterface: true)
        XCTAssertEqual(
            client.buildHeartbeatRequest(pageIndex: Command.pageStatusCH2, expectedLength: 26),
            FrameCodec.buildHeartbeat(pageIndex: Command.pageStatusCH2, expectedLen: 26)
        )
    }

    func testHandleFrameClassifiesPairingResponses() {
        let client = ProtocolClient()
        let frame = ParsedFrame(cmd: Command.deviceInfo, data: [0x41, 0x07, 0x01, 0x02, 0x03])

        let events = client.handleFrame(frame)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first, .rawFrame(frame))

        guard case let .pairingResult(.success(info)) = events[1] else {
            return XCTFail("expected pairingResult success")
        }

        XCTAssertEqual(info.siteName, "A07")
        XCTAssertEqual(info.fwVersion, FwVersion(1, 2, 3))
    }

    func testHandleFrameClassifiesStatusResultsWithoutDroppingParsedMeasurement() {
        let client = ProtocolClient(isInterface: true)
        let frame = ParsedFrame(cmd: Command.statusCH2, data: interfaceStatusPayload())

        let events = client.handleFrame(frame)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.first, .rawFrame(frame))

        guard case let .parsedMeasurement(result) = events[1] else {
            return XCTFail("expected parsedMeasurement")
        }

        guard case let .statusResult(statusResult) = events[2] else {
            return XCTFail("expected statusResult")
        }

        guard case let .interfaceStatus(reading, _, _, _, _, _, freqMHz, _, _, _, _, trendRecord) = result else {
            return XCTFail("expected interfaceStatus parse result")
        }

        XCTAssertEqual(result, statusResult)
        XCTAssertEqual(reading.level, 3.21, accuracy: 0.0001)
        XCTAssertEqual(reading.heavyLevel, 6.54, accuracy: 0.0001)
        XCTAssertEqual(freqMHz, 0.160, accuracy: 0.0001)
        XCTAssertEqual(trendRecord.eeaD, 654)
    }

    func testHandleFrameClassifiesDiagnosticResults() {
        let client = ProtocolClient()
        let payload = u16(0x0100) + u16(0x04D2) + u16(30) + u16(0x0190) + u16(0x07D0) + u16(2) + u16(0x017C) + u16(9)
        let frame = ParsedFrame(cmd: Command.diag, data: payload)

        let events = client.handleFrame(frame)

        XCTAssertEqual(events.count, 3)

        guard case let .parsedMeasurement(result) = events[1] else {
            return XCTFail("expected parsedMeasurement")
        }

        guard case let .diagnosticResult(diagResult) = events[2] else {
            return XCTFail("expected diagnosticResult")
        }

        guard case let .densityDiag(diag) = result else {
            return XCTFail("expected densityDiag parse result")
        }

        XCTAssertEqual(result, diagResult)
        XCTAssertEqual(diag.temperature, 25.6, accuracy: 0.0001)
        XCTAssertEqual(diag.currentMA, 12.34, accuracy: 0.0001)
    }

    private func interfaceStatusPayload() -> [UInt8] {
        u16(321) + u16(654) + i16(250) + u16(1500) + u16(2) + i16(-25) +
        u16(100) + u16(2000) + u16(8) + u16(5) + u16(3) + u16(1) + u16(2)
    }

    private func u16(_ value: Int) -> [UInt8] {
        [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    private func i16(_ value: Int) -> [UInt8] {
        let raw = UInt16(bitPattern: Int16(value))
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }
}
