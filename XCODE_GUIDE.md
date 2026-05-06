# WWS2 iOS / Swift 작업 가이드

이 폴더는 Windows/WSL에서 만든 iOS 포팅 starter입니다.

## 구성

- `Package.swift`
  - `WWS2Core` Swift Package
  - CRC, FrameCodec, ProtocolModels, Parser, StreamParser 테스트 가능
- `Sources/WWS2Core`
  - Android Kotlin의 순수 로직을 Swift로 포팅한 라이브러리
- `Tests/WWS2CoreTests`
  - CRC known vector, Frame round-trip, parser sanity tests
- `iOSApp`
  - Xcode iOS App target에 넣을 SwiftUI/CoreBluetooth skeleton

## Mac/Xcode에서 여는 법

1. Mac으로 이 폴더 전체를 복사
2. Xcode 실행
3. `File > Open...`에서 이 폴더의 `Package.swift` 열기
4. 먼저 `WWS2CoreTests` 실행
5. 실제 iOS 앱 생성:
   - Xcode > File > New > Project > iOS App
   - Product Name: `WESSWARE`
   - Interface: SwiftUI
   - Language: Swift
   - Bundle ID 예: `com.wessware.wws2`
6. 생성된 앱 target에 Swift Package `WWS2Core`를 dependency로 추가
7. `iOSApp/` 안의 파일들을 앱 target으로 복사
8. `Info.plist`에 Bluetooth 권한 문구 추가
9. 실제 iPhone 연결 후 BLE 테스트

## 중요 제약

- iOS Simulator는 BLE 장비 테스트 불가. 실제 iPhone 필요.
- iOS는 BLE MAC address를 제공하지 않음. `CBPeripheral.identifier`와 device-info 응답으로 장비 식별해야 함.
- Android `requestMtu(247)` 대응 API가 iOS에는 없음. `maximumWriteValueLength(for:)` 기준으로 chunking함.
- Android `setPreferredPhy(2M)`는 iOS 앱에서 강제 불가.
- Background BLE는 `bluetooth-central` capability가 필요하며 App Store 심사 사유가 필요할 수 있음.

## 지금 된 것

- Command/Crc/FrameCodec/ProtocolModels Swift 포팅
- DeviceReading/EchoReading/TrendRecord/DiagReading/InterfaceEchoReading Swift 포팅
- FrameParser/TrendStreamParser/InterfaceEchoParser Swift 포팅
- CoreBluetooth scanner/connect/write/notify skeleton
- SwiftUI Main/Pairing/Echo/Trend/Menu skeleton
- XCTest 기본 테스트

## 아직 Mac/iPhone에서 해야 할 것

- `swift test` 또는 Xcode Test 실행
- 실제 장비 광고명/서비스/characteristic 확인
- PIN pairing 응답의 실제 DeviceInfo 세부 필드 확인
- streaming frame 조립 로직 실장/검증
- OTA 업로드 chunking 실제 장비 검증
- CSV import/export 및 share sheet 연결
- 앱 아이콘, Bundle ID, Signing, TestFlight 설정
