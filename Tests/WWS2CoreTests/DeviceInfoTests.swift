import XCTest
@testable import WWS2Core

final class DeviceInfoTests: XCTestCase {
    func testFromPayloadParsesDensityLayout() throws {
        let payload: [UInt8] = [0x41, 0x07, 0x01, 0x02, 0x03]

        let info = try XCTUnwrap(DeviceInfo.fromPayload(payload))
        XCTAssertEqual(info.siteName, "A07")
        XCTAssertEqual(info.ch2SiteName, "")
        XCTAssertFalse(info.isDualChannel)
        XCTAssertEqual(info.fwVersion, FwVersion(1, 2, 3))
        XCTAssertNil(info.serialNumber)
        XCTAssertEqual(info.rawPayload, payload)
    }

    func testFromPayloadParsesInterfaceLayout() throws {
        let payload: [UInt8] = [0x42, 0x08, 0x43, 0x09, 0x04, 0x05, 0x06]

        let info = try XCTUnwrap(DeviceInfo.fromPayload(payload))
        XCTAssertEqual(info.siteName, "B08")
        XCTAssertEqual(info.ch2SiteName, "C09")
        XCTAssertTrue(info.isDualChannel)
        XCTAssertEqual(info.fwVersion, FwVersion(4, 5, 6))
        XCTAssertNil(info.serialNumber)
        XCTAssertEqual(info.rawPayload, payload)
    }
}
