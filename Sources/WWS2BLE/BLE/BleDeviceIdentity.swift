import Foundation
import CoreBluetooth
import WWS2Core

public struct BleDeviceIdentity: Equatable, Identifiable, Sendable {
    public let id: String
    public let peripheralIdentifier: UUID
    public let advertisedName: String
    public let displayName: String
    public let productName: String
    public let ch1SiteName: String
    public let ch2SiteName: String
    public let isInterface: Bool
    public let rssi: Int
    public let serviceUUIDs: [String]
    public let manufacturerData: [UInt8]


    public init(
        peripheralIdentifier: UUID,
        advertisedName: String,
        rssi: Int,
        serviceUUIDs: [String] = [],
        manufacturerData: [UInt8] = []
    ) {
        let parsed = DeviceNameParser.displayName(rawName: advertisedName)
        self.peripheralIdentifier = peripheralIdentifier
        self.id = peripheralIdentifier.uuidString
        self.advertisedName = advertisedName
        self.displayName = parsed.displayName
        self.productName = parsed.productName
        self.ch1SiteName = parsed.ch1Site
        self.ch2SiteName = parsed.ch2Site
        self.isInterface = parsed.isInterface
        self.rssi = rssi
        self.serviceUUIDs = serviceUUIDs
        self.manufacturerData = manufacturerData
    }

    public init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        let advertisedName = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? "Unknown"
        let parsed = DeviceNameParser.displayName(rawName: advertisedName)
        self.peripheralIdentifier = peripheral.identifier
        self.id = peripheral.identifier.uuidString
        self.advertisedName = advertisedName
        self.displayName = parsed.displayName
        self.productName = parsed.productName
        self.ch1SiteName = parsed.ch1Site
        self.ch2SiteName = parsed.ch2Site
        self.isInterface = parsed.isInterface
        self.rssi = rssi.intValue
        self.serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []).map { $0.uuidString }
        self.manufacturerData = Array((advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data) ?? Data())
    }
}
