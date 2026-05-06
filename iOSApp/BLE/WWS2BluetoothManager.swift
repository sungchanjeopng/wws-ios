#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth
import Combine
import WWS2Core

public final class WWS2BluetoothManager: NSObject, ObservableObject {
    @Published public private(set) var bluetoothState: CBManagerState = .unknown
    @Published public private(set) var scannedDevices: [UUID: ScannedDevice] = [:]
    @Published public private(set) var isScanning = false
    @Published public private(set) var connectedPeripheralID: UUID?
    @Published public private(set) var lastError: String?

    public let notifications = PassthroughSubject<[UInt8], Never>()
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    private var writeQueue = DispatchQueue(label: "wws2.ble.write")

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }

    public func startScan() {
        guard central.state == .poweredOn else { lastError = "Bluetooth is not powered on"; return }
        scannedDevices.removeAll()
        isScanning = true
        // Android는 이름 기반 필터. iOS도 우선 nil scan 후 advertisement/localName에서 W3/W2/WE13/WE23/ENV/CHIPSEN 필터.
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    public func stopScan() { central.stopScan(); isScanning = false }

    public func connect(_ id: UUID) {
        guard let p = discoveredPeripherals[id] else { lastError = "Peripheral not found"; return }
        peripheral = p
        p.delegate = self
        central.connect(p, options: nil)
    }

    public func disconnect() {
        if let p = peripheral { central.cancelPeripheralConnection(p) }
        connectedPeripheralID = nil; writeCharacteristic = nil; notifyCharacteristic = nil
    }

    public func write(_ bytes: [UInt8], withoutResponse: Bool = false) {
        guard let p = peripheral, let c = writeCharacteristic else { lastError = "Write characteristic missing"; return }
        let type: CBCharacteristicWriteType = withoutResponse && c.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        let maxLen = p.maximumWriteValueLength(for: type)
        var offset = 0
        while offset < bytes.count {
            let end = min(offset + maxLen, bytes.count)
            p.writeValue(Data(bytes[offset..<end]), for: c, type: type)
            offset = end
        }
    }

    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]

    private static func deviceType(name: String) -> DeviceType {
        let up = name.uppercased()
        if up.starts(with: "W3") || up.contains("130") || up.contains("WE13") || up.contains("INTERFACE") { return .interface }
        if up.starts(with: "W2") || up.contains("230") || up.contains("WE23") || up.contains("ENV") || up.contains("CHIPSEN") { return .density }
        return .unknown
    }

    private static func isCandidate(name: String) -> Bool {
        let up = name.uppercased()
        return up.starts(with: "W3") || up.starts(with: "W2") || up.contains("WE13") || up.contains("WE23") || up.contains("ENV") || up.contains("CHIPSEN")
    }
}

extension WWS2BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) { bluetoothState = central.state }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? "Unknown"
        guard Self.isCandidate(name: name) else { return }
        discoveredPeripherals[peripheral.identifier] = peripheral
        let type = Self.deviceType(name: name)
        scannedDevices[peripheral.identifier] = ScannedDevice(id: peripheral.identifier, name: type == .interface ? "ENV130" : "ENV230", rawName: name, rssi: RSSI.intValue, type: type)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheralID = peripheral.identifier
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) { lastError = error?.localizedDescription ?? "Connect failed" }
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) { connectedPeripheralID = nil; writeCharacteristic = nil; notifyCharacteristic = nil }
}

extension WWS2BluetoothManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error { lastError = error.localizedDescription; return }
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error { lastError = error.localizedDescription; return }
        for c in service.characteristics ?? [] {
            if notifyCharacteristic == nil && (c.properties.contains(.notify) || c.properties.contains(.indicate)) {
                notifyCharacteristic = c
                peripheral.setNotifyValue(true, for: c)
            }
            if c.properties.contains(.writeWithoutResponse) && writeCharacteristic == nil { writeCharacteristic = c }
            if c.properties.contains(.write) && writeCharacteristic == nil { writeCharacteristic = c }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value { notifications.send(data.bytes) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error { lastError = "Write failed: \(error.localizedDescription)" }
    }
}
#endif
