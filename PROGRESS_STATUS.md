# WWS2 iOS 포팅 진행 상태

생성 위치: `C:\Users\jeong\Downloads\wws2_ios`

## 완료

- Android 원본 기준 경로 확인: `C:\Users\jeong\Downloads\wws2_android`
- 별도 iOS workspace 생성
- Swift Package `WWS2Core` 생성
- Kotlin 순수 BLE 프로토콜 로직 Swift 변환
  - `Command.swift`
  - `Crc.swift`
  - `FrameCodec.swift`
  - `ProtocolModels.swift`
- 주요 도메인 모델 Swift 변환
  - `DeviceReading`
  - `EchoReading`
  - `InterfaceEchoReading`
  - `TrendRecord`
  - `DiagReading`
  - `InterfaceDiagReading`
- Parser Swift 변환
  - `FrameParser`
  - `TrendStreamParser`
  - `InterfaceEchoParser`
- iOS App skeleton 작성
  - CoreBluetooth manager
  - SwiftUI shell/main/pairing/echo/trend/menu
  - AppViewModel
- 테스트 작성
  - CRC known vectors
  - Frame round-trip
  - bad CRC reject
  - parser sanity tests

## 남은 필수 검증

- Mac/Xcode에서 `WWS2CoreTests` 실행
- 실제 iPhone + WESSWARE 장비로 BLE scan/connect/notify/write 검증
- 장비가 보내는 실제 raw frame 저장 후 parser test case 추가
- CoreBluetooth characteristic 선택이 실제 장비와 맞는지 확인
- PIN pairing 성공 후 device-info 세부 파싱 확장
- OTA/Download streaming은 실제 장비 데이터로 재검증 필요

## 보안 메모

- Android 쪽 signing password/API key는 공유/커밋 전에 정리 필요.
- iOS 앱에 OpenAI API key를 직접 넣지 않는 편이 안전함. 가능하면 서버 proxy 권장.
