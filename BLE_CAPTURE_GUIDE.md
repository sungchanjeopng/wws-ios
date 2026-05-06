# BLE Capture Guide

This guide lists the exact BLE details that still need to be captured from a real WESSWARE device before the iOS port can be considered validated.

## 1. Capture Environment

Use at least one of:

- iPhone app logs from the iOS port
- nRF Connect on Android
- macOS Bluetooth debugging tools

If possible, capture from both Android and iPhone so command ordering and chunk boundaries can be compared.

## 2. Identity Data To Capture

For each test device, record:

- Advertisement local name
- Advertised service UUIDs
- Manufacturer data bytes
- Whether the device appears to be single-channel or interface / dual-channel
- On iPhone, the `CBPeripheral.identifier`

Important:

- iOS will not expose the BLE MAC address.
- Do not block iOS identity logic on MAC capture. Use `CBPeripheral.identifier`, advertisement metadata, and `DeviceInfo`.

## 3. GATT Data To Capture

Record the real values for:

- Service UUID
- Write characteristic UUID
- Notify characteristic UUID
- Whether notify actually uses `.notify`, `.indicate`, or both
- Whether write actually uses `.writeWithoutResponse`, `.write`, or both

Also record the iPhone write limits:

- `maximumWriteValueLength(for: .withoutResponse)`
- `maximumWriteValueLength(for: .withResponse)`

This matters because iOS cannot request Android MTU 247.

## 4. Raw Hex Frames To Capture

For every capture below, save:

- TX or RX direction
- absolute timestamp
- command/page index if known
- full raw hex bytes
- whether the frame arrived in a single notification or multiple chunks

### Pairing / Device Info

Capture:

- pairing request frame (`0x00F0`)
- successful pairing response frame
- failed PIN response frame

### Status

Capture:

- CH1 / density status (`0x0000`)
- CH2 / interface status (`0x0010`) if the device supports it

### Echo

Capture:

- density echo (`0x0001`)
- interface echo / alternate echo pages if used by firmware

### Diagnostics

Capture:

- density diag (`0x0004`)
- interface diag (`0x0014`)

### Trend / Download

Capture:

- trend header
- trend record body chunks
- final CRC trailer
- download page variants (`0x0007`, `0x0017`) if firmware uses them

### OTA

Capture:

- OTA start request / response
- OTA chunk ack behavior
- OTA end request / response
- any OTA error or retry frames

OTA is still intentionally last and should not be treated as validated yet.

## 5. Recommended Logging Format

Use a simple text format per event, for example:

```text
2026-05-04T14:23:10.115Z RX uuid=FFF1 bytes=02 00 F0 41 07 01 02 03 xx xx
2026-05-04T14:23:10.420Z TX uuid=FFF2 bytes=02 00 00 00 1A xx xx
```

For multi-chunk notifications, log each chunk separately and also log the reassembled frame if your tool allows it.

## 6. What To Do With The Captures

After capture:

1. Replace placeholder UUIDs in `WesswareBLEUUIDs.swift`.
2. Tighten discovery logic in `BlePeripheralSession.swift` if the UUIDs are stable.
3. Add the raw hex samples as XCTest fixtures.
4. Re-run `swift test` on Mac.
5. Only after scan/connect/pairing/status/diag/trend are stable should OTA work continue.
