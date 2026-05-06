import Foundation
import WWS2Core

public struct ResolvedPeripheralIdentity: Equatable, Identifiable, Sendable {
    public let id: String
    public let peripheralIdentifier: UUID
    public let protocolIdentityKey: String
    public let advertisedName: String
    public let displayName: String
    public let productName: String
    public let ch1SiteName: String
    public let ch2SiteName: String
    public let isInterface: Bool
    public let serviceUUIDs: [String]
    public let manufacturerData: [UInt8]
    public let deviceInfo: DeviceInfo?

    public init(
        id: String,
        peripheralIdentifier: UUID,
        protocolIdentityKey: String,
        advertisedName: String,
        displayName: String,
        productName: String,
        ch1SiteName: String,
        ch2SiteName: String,
        isInterface: Bool,
        serviceUUIDs: [String],
        manufacturerData: [UInt8],
        deviceInfo: DeviceInfo?
    ) {
        self.id = id
        self.peripheralIdentifier = peripheralIdentifier
        self.protocolIdentityKey = protocolIdentityKey
        self.advertisedName = advertisedName
        self.displayName = displayName
        self.productName = productName
        self.ch1SiteName = ch1SiteName
        self.ch2SiteName = ch2SiteName
        self.isInterface = isInterface
        self.serviceUUIDs = serviceUUIDs
        self.manufacturerData = manufacturerData
        self.deviceInfo = deviceInfo
    }
}

/// iOS cannot expose the BLE MAC address. Pairing state should therefore be resolved from
/// `CBPeripheral.identifier`, advertisement metadata, and the optional 0xF0 device-info response.
public final class PairingManager {
    public init() {}

    public func makeDeviceInfoRequest(pin: Int) -> [UInt8] {
        FrameCodec.buildDeviceInfoRequest(pin: pin)
    }

    public func resolveIdentity(
        peripheralIdentifier: UUID,
        advertisedName: String,
        serviceUUIDs: [String] = [],
        manufacturerData: [UInt8] = [],
        pairingResult: PairingResult?
    ) -> ResolvedPeripheralIdentity {
        let parsedName = DeviceNameParser.displayName(rawName: advertisedName)
        let deviceInfo = pairingResult.flatMap(Self.deviceInfo(from:))

        let ch1Site = firstNonEmpty(deviceInfo?.siteName, parsedName.ch1Site)
        let ch2Site = firstNonEmpty(deviceInfo?.ch2SiteName, parsedName.ch2Site)
        let isInterface = deviceInfo?.isDualChannel ?? parsedName.isInterface
        let productName = isInterface ? "ENV130" : parsedName.productName

        let displayName: String
        if !ch1Site.isEmpty && !ch2Site.isEmpty {
            displayName = "\(productName)  \(ch1Site) / \(ch2Site)"
        } else if !ch1Site.isEmpty {
            displayName = "\(productName)_\(ch1Site)"
        } else if !parsedName.displayName.isEmpty {
            displayName = parsedName.displayName
        } else {
            displayName = productName
        }

        let protocolIdentityKey = makeProtocolIdentityKey(
            productName: productName,
            ch1Site: ch1Site,
            ch2Site: ch2Site,
            deviceInfo: deviceInfo
        )

        return ResolvedPeripheralIdentity(
            id: peripheralIdentifier.uuidString,
            peripheralIdentifier: peripheralIdentifier,
            protocolIdentityKey: protocolIdentityKey,
            advertisedName: advertisedName,
            displayName: displayName,
            productName: productName,
            ch1SiteName: ch1Site,
            ch2SiteName: ch2Site,
            isInterface: isInterface,
            serviceUUIDs: serviceUUIDs,
            manufacturerData: manufacturerData,
            deviceInfo: deviceInfo
        )
    }

    private func makeProtocolIdentityKey(
        productName: String,
        ch1Site: String,
        ch2Site: String,
        deviceInfo: DeviceInfo?
    ) -> String {
        if let serialNumber = deviceInfo?.serialNumber, !serialNumber.isEmpty {
            return "\(productName):SERIAL:\(serialNumber)"
        }

        if !ch1Site.isEmpty || !ch2Site.isEmpty {
            return "\(productName):\(ch1Site):\(ch2Site)"
        }

        return productName
    }

    private func firstNonEmpty(_ values: String?...) -> String {
        for value in values {
            if let value, !value.isEmpty {
                return value
            }
        }

        return ""
    }

    private static func deviceInfo(from result: PairingResult) -> DeviceInfo? {
        guard case let .success(info) = result else { return nil }
        return info.isPlaceholder ? nil : info
    }
}
