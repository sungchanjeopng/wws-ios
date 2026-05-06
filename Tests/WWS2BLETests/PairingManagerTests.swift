import XCTest
@testable import WWS2BLE
import WWS2Core

final class PairingManagerTests: XCTestCase {
    func testResolveIdentityUsesDeviceInfoAndNotMacAddress() throws {
        let manager = PairingManager()
        let identifier = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000123"))
        let pairingResult = PairingResult.success(
            DeviceInfo(
                siteNameHi: "A",
                siteNameLo: 7,
                ch2SiteNameHi: "B",
                ch2SiteNameLo: 8,
                fwVersion: FwVersion(1, 2, 3),
                serialNumber: "SN-001"
            )
        )

        let resolved = manager.resolveIdentity(
            peripheralIdentifier: identifier,
            advertisedName: "W3OLDOLD",
            serviceUUIDs: ["FFF0"],
            manufacturerData: [0x01, 0x02],
            pairingResult: pairingResult
        )

        XCTAssertEqual(resolved.id, identifier.uuidString)
        XCTAssertEqual(resolved.displayName, "ENV130  A07 / B08")
        XCTAssertEqual(resolved.protocolIdentityKey, "ENV130:SERIAL:SN-001")
        XCTAssertTrue(resolved.isInterface)
        XCTAssertEqual(resolved.serviceUUIDs, ["FFF0"])
        XCTAssertEqual(resolved.manufacturerData, [0x01, 0x02])
    }
}
