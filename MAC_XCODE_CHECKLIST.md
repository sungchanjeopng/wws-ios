# Mac / Xcode Checklist

Use this checklist on a Mac with Xcode installed. The current Windows workspace does not have a Swift toolchain.

## 1. Open The Package

1. Copy or clone the repo to the Mac.
2. Open Terminal.
3. Change into the iOS workspace:

```bash
cd ~/Downloads/wws2_ios
```

4. Open the package in Xcode:

```bash
open Package.swift
```

## 2. Run Package Tests

From Terminal in `~/Downloads/wws2_ios`:

```bash
swift test
```

If `swift test` fails, capture the exact compiler/test output and feed it back into the next repair pass.

## 3. Build The App Target

Inside Xcode:

1. Wait for package indexing to finish.
2. Inspect the available schemes.
3. Select the `WWS2iOSApp` scheme/target if Xcode exposes it directly from the package.
4. Build with:
   - `Product` -> `Build`
   - or `Cmd+B`

If Xcode does not produce an installable iPhone app from the package alone, create a small iOS app host project and link these package targets:

- `WWS2Core`
- `WWS2BLE`
- `WWS2iOSApp`

## 4. Add Bluetooth Permission Strings In A Real App Project

Swift packages do not own an app `Info.plist`. If you create or use a real iOS app target, add the Bluetooth permission strings there:

- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`
  - Add this if your deployment target / host project still requires it.

Example purpose text:

- "Bluetooth is used to connect to nearby WESSWARE measurement devices."

## 5. Test On A Physical iPhone

Use a real iPhone and a real WESSWARE device. The simulator is not enough for BLE validation.

Checklist:

1. Install the app on iPhone.
2. Accept Bluetooth permission prompts.
3. Confirm scan results appear.
4. Connect to a real device.
5. Attempt pairing.
6. Verify notification traffic after pairing and heartbeat requests.
7. Record the observed write lengths from:
   - `maximumWriteValueLength(for: .withoutResponse)`
   - `maximumWriteValueLength(for: .withResponse)`

## 6. Scope Limits To Keep In Mind

- iOS cannot expose the BLE MAC address.
- iOS cannot request Android MTU 247.
- iOS cannot force PHY 2M.
- Final BLE and OTA validation requires:
  - Mac
  - Xcode
  - physical iPhone
  - physical WESSWARE device
