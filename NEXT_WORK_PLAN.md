# WWS2 iOS Next Work Plan

Workspace:
`C:\Users\jeong\Downloads\wws2_ios`

## 1. Immediate Mac / Xcode Validation

1. Open `Package.swift` on a Mac in Xcode.
2. Run `swift test` from Terminal in the package directory.
3. Fix any compile issues surfaced by the Apple Swift toolchain.
4. Build the `WWS2iOSApp` target/scheme that Xcode exposes from the package.
5. If an installable iPhone app host project is needed, create a thin app target that links `WWS2Core`, `WWS2BLE`, and `WWS2iOSApp` code, then add the Bluetooth permission strings there.
6. Run the build on a physical iPhone.

## 2. BLE Hardware Validation

1. Capture the real WESSWARE BLE Service/Write/Notify UUIDs.
2. Confirm whether the chosen write characteristic supports:
   - `.writeWithoutResponse`
   - `.write`
   - or both
3. Verify the selected notify characteristic uses `.notify`, `.indicate`, or both.
4. Record the actual `maximumWriteValueLength(for: .withoutResponse)` and `maximumWriteValueLength(for: .withResponse)` values on iPhone.
5. Test real connect -> pairing -> heartbeat -> status flow with the new session methods.

## 3. Parser / Export Validation With Real Captures

1. Capture raw hex for:
   - device info / pairing
   - status
   - echo
   - diagnostics
   - trend / download
   - OTA ack / error
2. Add those captures as XCTest fixtures.
3. Compare generated CSV output with real trend data samples.

## 4. Follow-On Code Work After Hardware Results

1. Replace placeholder BLE UUIDs with captured values.
2. Tighten characteristic discovery if the real UUIDs are stable.
3. Add session-level write pacing/ack handling if iPhone testing shows chunk timing problems.
4. Promote CSV preview to actual file export/share flow from a real iOS app host target.
5. Only after all non-OTA BLE flows are stable, start OTA implementation/validation.
