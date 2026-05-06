import Foundation
import CoreBluetooth
import WWS2Core

/// One connected CoreBluetooth peripheral session.
/// TODO: Replace generic service/characteristic discovery with real WESSWARE UUIDs after confirming
/// service/write/notify UUIDs from a physical device or nRF Connect capture.
public final class BlePeripheralSession: NSObject, CBPeripheralDelegate {
    public let peripheral: CBPeripheral
    public let protocolClient: ProtocolClient

    public private(set) var writeCharacteristic: CBCharacteristic?
    public private(set) var notifyCharacteristic: CBCharacteristic?
    public var onEvent: ((ProtocolClientEvent) -> Void)?
    public var onReady: (() -> Void)?

    public init(peripheral: CBPeripheral, isInterface: Bool = false) {
        self.peripheral = peripheral
        self.protocolClient = ProtocolClient(isInterface: isInterface)
        super.init()
        self.peripheral.delegate = self
    }

    public func updateIsInterface(_ isInterface: Bool) {
        protocolClient.isInterface = isInterface
    }

    public func discover(serviceUUIDs: [CBUUID]? = nil) {
        peripheral.discoverServices(serviceUUIDs)
    }

    public var canWriteFrames: Bool {
        writeCharacteristic != nil
    }

    @discardableResult
    public func write(_ bytes: [UInt8], withoutResponse: Bool = false) -> Bool {
        guard let characteristic = writeCharacteristic else { return false }
        let type = resolvedWriteType(preferWithoutResponse: withoutResponse, characteristic: characteristic)
        return writeChunks(bytes, to: characteristic, type: type)
    }

    /// iOS cannot request Android-style MTU 247. Frame writes must be chunked according to
    /// `maximumWriteValueLength(for:)` for the selected characteristic write type.
    @discardableResult
    public func writeFrame(_ bytes: [UInt8]) -> Bool {
        guard let characteristic = writeCharacteristic else { return false }
        return writeChunks(bytes, to: characteristic, type: preferredWriteType(for: characteristic))
    }

    @discardableResult
    public func requestPairing(pin: Int) -> Bool {
        writeFrame(protocolClient.buildPairingRequest(pin: pin))
    }

    @discardableResult
    public func writeDeviceInfoRequest(pin: Int, withoutResponse: Bool = false) -> Bool {
        let frame = protocolClient.buildPairingRequest(pin: pin)
        return write(frame, withoutResponse: withoutResponse)
    }

    @discardableResult
    public func requestHeartbeat(pageIndex: Int, expectedLength: Int = 0) -> Bool {
        writeFrame(protocolClient.buildHeartbeatRequest(pageIndex: pageIndex, expectedLength: expectedLength))
    }

    public func maximumWriteLength(withoutResponse: Bool = true) -> Int {
        let type: CBCharacteristicWriteType = withoutResponse ? .withoutResponse : .withResponse
        return peripheral.maximumWriteValueLength(for: type)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        let characteristics = service.characteristics ?? []

        if writeCharacteristic == nil {
            writeCharacteristic = selectWriteCharacteristic(from: characteristics)
        }

        if notifyCharacteristic == nil, let notify = selectNotifyCharacteristic(from: characteristics) {
            notifyCharacteristic = notify
            peripheral.setNotifyValue(true, for: notify)
        }

        if writeCharacteristic != nil && notifyCharacteristic != nil {
            onReady?()
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, error == nil else { return }
        let events = protocolClient.handleNotificationChunk(Array(data))
        for event in events {
            onEvent?(event)
        }
    }

    private func selectWriteCharacteristic(from characteristics: [CBCharacteristic]) -> CBCharacteristic? {
        if let matched = characteristics.first(where: { isPreferredWriteCharacteristic($0) }) {
            return matched
        }

        return characteristics.first(where: isWritableCharacteristic)
    }

    private func selectNotifyCharacteristic(from characteristics: [CBCharacteristic]) -> CBCharacteristic? {
        if let matched = characteristics.first(where: { isPreferredNotifyCharacteristic($0) }) {
            return matched
        }

        return characteristics.first(where: isNotifiableCharacteristic)
    }

    private func isPreferredWriteCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        WesswareBLEUUIDs.writeCandidates.contains(characteristic.uuid) && isWritableCharacteristic(characteristic)
    }

    private func isPreferredNotifyCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        WesswareBLEUUIDs.notifyCandidates.contains(characteristic.uuid) && isNotifiableCharacteristic(characteristic)
    }

    private func isWritableCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write)
    }

    private func isNotifiableCharacteristic(_ characteristic: CBCharacteristic) -> Bool {
        characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
    }

    private func preferredWriteType(for characteristic: CBCharacteristic) -> CBCharacteristicWriteType {
        characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
    }

    private func resolvedWriteType(
        preferWithoutResponse: Bool,
        characteristic: CBCharacteristic
    ) -> CBCharacteristicWriteType {
        if preferWithoutResponse, characteristic.properties.contains(.writeWithoutResponse) {
            return .withoutResponse
        }

        if characteristic.properties.contains(.write) {
            return .withResponse
        }

        return preferredWriteType(for: characteristic)
    }

    private func writeChunks(
        _ bytes: [UInt8],
        to characteristic: CBCharacteristic,
        type: CBCharacteristicWriteType
    ) -> Bool {
        guard !bytes.isEmpty else { return false }

        let maxChunkLength = max(1, peripheral.maximumWriteValueLength(for: type))
        var startIndex = 0

        while startIndex < bytes.count {
            let endIndex = min(startIndex + maxChunkLength, bytes.count)
            let chunk = Data(Array(bytes[startIndex..<endIndex]))
            peripheral.writeValue(chunk, for: characteristic, type: type)
            startIndex = endIndex
        }

        return true
    }
}
