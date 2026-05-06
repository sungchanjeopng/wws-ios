import Foundation
import Combine
import CoreBluetooth
import WWS2Core

/// CoreBluetooth scan/connect skeleton for WESSWARE devices.
/// TODO: Constrain scanning/discovery to the real WESSWARE BLE service UUIDs once verified.
public final class BleCentralManager: NSObject, ObservableObject {
    @Published public private(set) var isBluetoothReady = false
    @Published public private(set) var discovered: [BleDeviceIdentity] = []
    @Published public private(set) var connectedPeripheralIdentifiers: [UUID] = []

    public var onSessionEvent: ((UUID, ProtocolClientEvent) -> Void)?
    public var onConnectionStateChanged: ((UUID, Bool, Error?) -> Void)?
    public var onSessionReady: ((UUID) -> Void)?

    public var discoveredPublisher: Published<[BleDeviceIdentity]>.Publisher { $discovered }
    public var isBluetoothReadyPublisher: Published<Bool>.Publisher { $isBluetoothReady }

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var sessions: [UUID: BlePeripheralSession] = [:]

    public override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    public func startScan() {
        guard central.state == .poweredOn else { return }
        discovered.removeAll()
        // iOS cannot force PHY 2M and should not assume Android's MAC-oriented discovery flow.
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    public func stopScan() {
        central.stopScan()
    }

    public func connect(id: UUID) {
        guard sessions[id] == nil, let peripheral = peripherals[id] else { return }
        stopScan()
        central.connect(peripheral, options: nil)
    }

    public func disconnect(id: UUID) {
        guard let peripheral = peripherals[id] else { return }
        central.cancelPeripheralConnection(peripheral)
    }

    public func disconnectAll() {
        for identifier in connectedPeripheralIdentifiers {
            disconnect(id: identifier)
        }
    }

    public func session(id: UUID) -> BlePeripheralSession? {
        sessions[id]
    }

    public func connectedSession(for id: UUID?) -> BlePeripheralSession? {
        guard let id else { return nil }
        return sessions[id]
    }

    public func isConnected(id: UUID) -> Bool {
        sessions[id] != nil
    }

    private func isWesswareName(_ name: String) -> Bool {
        DeviceNameParser.isWesswareName(name)
    }
}

extension BleCentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothReady = central.state == .poweredOn
        guard central.state == .poweredOn else {
            discovered.removeAll()
            sessions.removeAll()
            connectedPeripheralIdentifiers.removeAll()
            return
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? ""
        guard !name.isEmpty, isWesswareName(name) else { return }

        peripherals[peripheral.identifier] = peripheral
        let identity = BleDeviceIdentity(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)

        if let index = discovered.firstIndex(where: { $0.id == identity.id }) {
            discovered[index] = identity
        } else {
            discovered.append(identity)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let isInterface = discovered.first(where: { $0.peripheralIdentifier == peripheral.identifier })?.isInterface ?? false
        let session = BlePeripheralSession(peripheral: peripheral, isInterface: isInterface)
        session.onEvent = { [weak self] event in
            self?.onSessionEvent?(peripheral.identifier, event)
        }
        session.onReady = { [weak self] in
            self?.onSessionReady?(peripheral.identifier)
        }

        sessions[peripheral.identifier] = session
        connectedPeripheralIdentifiers = Array(sessions.keys)
        onConnectionStateChanged?(peripheral.identifier, true, nil)
        session.discover(WesswareBLEUUIDs.serviceCandidates)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        sessions.removeValue(forKey: peripheral.identifier)
        connectedPeripheralIdentifiers = Array(sessions.keys)
        onConnectionStateChanged?(peripheral.identifier, false, error)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        sessions.removeValue(forKey: peripheral.identifier)
        connectedPeripheralIdentifiers = Array(sessions.keys)
        onConnectionStateChanged?(peripheral.identifier, false, error)
    }
}
