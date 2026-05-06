# BLE_VALIDATION_CHECKLIST

이 문서는 WWS2 iOS 포팅에서 실제 iPhone + WESSWARE 장비로 확인해야 할 BLE 항목입니다.

## 1. 광고/식별 정보

각 장비별로 기록:

- 장비 모델: ENV130 / ENV230 / 기타
- 광고 Local Name
- Advertised Service UUIDs
- Manufacturer Data bytes
- iPhone에서 보이는 `CBPeripheral.identifier`
- Android에서 보이는 장비명/MAC 주소와의 대응 관계

주의:

- iOS는 BLE MAC address를 노출하지 않습니다.
- iOS 식별은 `CBPeripheral.identifier`, advertisement data, service UUID, device-info response, serial/name 조합으로 해야 합니다.

## 2. GATT 정보

실제 값 기록:

- Service UUID
- Write Characteristic UUID
- Notify Characteristic UUID
- CCCD 설정 필요 여부
- write characteristic property:
  - `.writeWithoutResponse`
  - `.write`
  - 둘 다 가능 여부
- notify characteristic property:
  - `.notify`
  - `.indicate`
  - 둘 다 가능 여부

## 3. iOS write length

iPhone에서 실제 값 기록:

```swift
peripheral.maximumWriteValueLength(for: .withoutResponse)
peripheral.maximumWriteValueLength(for: .withResponse)
```

이 값은 Android `requestMtu(247)`과 다르므로 OTA/download/upload chunking 검증에 중요합니다.

## 4. Pairing 검증

기록할 raw hex:

- pairing request frame
- pairing success response frame
- wrong PIN response frame
- timeout / no response case

확인할 것:

- PIN 입력 후 request가 실제 write characteristic으로 나가는지
- response가 notify characteristic으로 들어오는지
- DeviceInfo parsing 결과가 Android와 같은지

## 5. Status 검증

기록할 raw hex:

- Density status: `0x0000`
- Interface/CH2 status: `0x0010`

확인할 것:

- level/distance/current/temperature/frequency scale이 Android와 같은지
- parser 결과가 실제 앱 화면과 맞는지

## 6. Echo 검증

기록할 raw hex:

- Density echo: `0x0001`
- Interface echo 관련 frame
- multi-chunk로 들어오는 경우 chunk boundary

확인할 것:

- sample count
- waveform 값
- 마지막 CRC 검증
- Android 그래프와 Swift 그래프 비교

## 7. Diagnostics 검증

기록할 raw hex:

- Density diagnostics: `0x0004`
- Interface diagnostics: `0x0014` 또는 실제 장비 command

확인할 것:

- 진단 값 scale
- enum/status mapping
- Android 결과와 일치 여부

## 8. Trend / Download 검증

기록할 raw hex:

- trend header
- chunk frames
- end frame
- cancel/error frame

확인할 것:

- record size 24 bytes 검증
- running CRC 검증
- CSVBuilder 결과와 Android CSV 비교

## 9. OTA / Upload 검증

OTA는 위험도가 높으므로 다음이 안정된 뒤 진행합니다.

선행 조건:

- scan/connect 안정
- pairing 안정
- notify/write 안정
- status/echo/diag/trend 수신 안정

기록할 것:

- OTA start frame
- chunk size
- ack/nack frame
- retry 조건
- OTA end frame

주의:

- 실제 장비 펌웨어 손상 위험이 있으므로 테스트 장비에서만 검증하세요.
