# WWS2 iOS Port

Android project source: `C:\Users\jeong\Downloads\wws2_android`

This folder starts the iOS Swift/SwiftUI port.

Current focus:
1. Pure protocol logic: Command, CRC, FrameCodec, Parser, Models
2. XCTest test vectors
3. CoreBluetooth POC skeleton
4. SwiftUI screen skeleton

Important iOS BLE differences:
- iOS does not expose BLE MAC address. Use `CBPeripheral.identifier` + advertisement + device-info response.
- iOS cannot request Android-style MTU. Use `maximumWriteValueLength(for:)`.
- iOS cannot force Android-style PHY 2M.
- Real iPhone + real WESSWARE device is required for BLE testing.
