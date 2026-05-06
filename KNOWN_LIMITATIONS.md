# KNOWN_LIMITATIONS

이 폴더의 현재 한계와 미검증 항목입니다.

## 빌드 관련

- Windows/WSL 환경에서 Swift toolchain이 없어 `swift test`는 실행하지 못했습니다.
- Xcode 빌드는 아직 수행되지 않았습니다.
- 실제 iOS App target, signing, provisioning, TestFlight 설정은 아직 없습니다.
- `Package.swift`는 Core/BLE 라이브러리와 테스트 검증 중심으로 정리되어 있습니다.
- SwiftUI App 코드는 유지되어 있지만 실제 Xcode iOS App target에 연결해야 합니다.

## BLE 관련

- 실제 WESSWARE BLE Service UUID, Write Characteristic UUID, Notify Characteristic UUID가 아직 확정되지 않았습니다.
- `WesswareBLEUUIDs.swift`의 UUID는 placeholder 후보입니다.
- iPhone에서 scan/connect/write/notify가 실제 장비와 맞는지 검증되지 않았습니다.
- iOS는 Android처럼 BLE MAC address를 제공하지 않습니다.
- iOS는 Android의 `requestMtu(247)` 방식과 다릅니다. `maximumWriteValueLength(for:)` 기준으로 chunking해야 합니다.
- iOS 앱 코드에서 Android식 PHY 2M 강제 설정은 어렵습니다.

## 데이터/파서 관련

- CRC, FrameCodec, Parser 테스트 파일은 있지만 실제 장비 raw frame fixture가 더 필요합니다.
- pairing/status/echo/diagnostics/trend/download/OTA 관련 실제 hex capture가 필요합니다.
- Android 앱 결과와 Swift parser 결과를 실제 frame 기준으로 1:1 비교해야 합니다.

## UI 관련

- SwiftUI 화면/ViewModel 코드는 유지되어 있습니다.
- 다만 실제 App target에서 컴파일/화면 전환/상태 연결이 검증된 것은 아닙니다.
- `Sources/WWS2iOSApp`와 `iOSApp`는 각각 다음 역할로 봅니다.
  - `Sources/WWS2iOSApp`: SwiftUI/ViewModel 모듈성 코드
  - `iOSApp`: Xcode App target 생성 시 참고/복사용 starter

## 보안 관련

- 모바일 앱에 OpenAI API key 같은 비밀키를 직접 넣는 것은 권장하지 않습니다.
- Android 원본의 signing/API key 관련 정보는 공유/커밋 전에 별도 정리해야 합니다.
- BLE raw log를 외부 공유할 때 장비 serial/site 정보가 포함될 수 있으니 확인이 필요합니다.
