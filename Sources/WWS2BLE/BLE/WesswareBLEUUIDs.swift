import Foundation
import CoreBluetooth

/// Central place for WESSWARE BLE UUIDs.
///
/// TODO: Replace placeholder values with real Service/Write/Notify UUIDs captured from Android
/// `GattClient.kt` + an iPhone CoreBluetooth scan against the physical WESSWARE device.
/// iOS cannot request Android-style MTU 247 and cannot force PHY 2M; write chunk size must be
/// calculated with `CBPeripheral.maximumWriteValueLength(for:)` inside `BlePeripheralSession`.
public enum WesswareBLEUUIDs {
    public static let placeholderService = CBUUID(string: "0000FFF0-0000-1000-8000-00805F9B34FB")
    public static let placeholderWrite = CBUUID(string: "0000FFF2-0000-1000-8000-00805F9B34FB")
    public static let placeholderNotify = CBUUID(string: "0000FFF1-0000-1000-8000-00805F9B34FB")

    public static let serviceCandidates: [CBUUID] = [placeholderService]
    public static let writeCandidates: [CBUUID] = [placeholderWrite]
    public static let notifyCandidates: [CBUUID] = [placeholderNotify]
}
