import XCTest
@testable import WWS2Core

final class DeviceNameParserTests: XCTestCase {
    func testW2NameParsing() {
        let parsed = DeviceNameParser.displayName(rawName: "W2ABC")

        XCTAssertEqual(parsed.productName, "ENV230")
        XCTAssertEqual(parsed.ch1Site, "ABC")
        XCTAssertEqual(parsed.displayName, "ENV230_ABC")
        XCTAssertFalse(parsed.isInterface)
    }

    func testW3DualSiteParsing() {
        let parsed = DeviceNameParser.displayName(rawName: "W3ABCDEF")

        XCTAssertEqual(parsed.productName, "ENV130")
        XCTAssertEqual(parsed.ch1Site, "ABC")
        XCTAssertEqual(parsed.ch2Site, "DEF")
        XCTAssertEqual(parsed.displayName, "ENV130  ABC / DEF")
        XCTAssertTrue(parsed.isInterface)
    }

    func testWE13StillMarksInterfaceEvenWithoutSites() {
        let parsed = DeviceNameParser.displayName(rawName: "WESS_V0.9_WE13")

        XCTAssertEqual(parsed.productName, "ENV130")
        XCTAssertTrue(parsed.isInterface)
    }

    func testWesswareNameDetection() {
        XCTAssertTrue(DeviceNameParser.isWesswareName("W2ABC"))
        XCTAssertTrue(DeviceNameParser.isWesswareName("CHIPSEN_ENV230"))
        XCTAssertFalse(DeviceNameParser.isWesswareName("Random Speaker"))
    }

    func testSignalLevel() {
        XCTAssertEqual(DeviceNameParser.signalLevel(rssi: -50), 3)
        XCTAssertEqual(DeviceNameParser.signalLevel(rssi: -60), 2)
        XCTAssertEqual(DeviceNameParser.signalLevel(rssi: -80), 1)
    }
}
