# WWS2 iOS - Mac 빌드 검증용 전달 패키지

이 폴더는 `C:\Users\jeong\Downloads\wws2_ios`에서 기능/UI/테스트 코드는 유지하고, Codex 작업 로그와 중간 작업 파일만 제외해서 만든 Mac 빌드 검증용 정리본입니다.

## 폴더 목적

Mac/Xcode 환경을 가진 사람이 이 폴더를 받아서 다음을 빠르게 확인할 수 있게 하는 것이 목적입니다.

1. Swift Package 열기
2. Core/BLE 테스트 실행
3. 컴파일 에러 확인
4. 실제 iOS App target 생성 또는 기존 app host에 코드 연결
5. iPhone + WESSWARE 장비로 BLE 검증

## 유지한 것

- `Sources/WWS2Core`
  - CRC, FrameCodec, Parser, Models, CSVBuilder 등 핵심 로직
- `Sources/WWS2BLE`
  - CoreBluetooth scan/connect/write/notify/pairing skeleton
- `Sources/WWS2iOSApp`
  - SwiftUI 화면/ViewModel 코드
- `Tests/WWS2CoreTests`
  - Core 로직 XCTest
- `Tests/WWS2BLETests`
  - BLE protocol/pairing 관련 XCTest
- `iOSApp`
  - 실제 Xcode iOS App target 생성 시 참고/복사용 starter
- 빌드/검증 관련 문서

## 제외한 것

- `codex_long_run.log`
- `CODEX_TASK.md`
- `CODEX_TASK_2.md`
- `CODEX_TASK_3.md`
- `CODEX_TASK_4_LONG.md`
- `run_codex_long.sh`

즉, 기능/UI/테스트 코드는 버리지 않았고 작업 흔적만 뺐습니다.

## 현재 Package.swift 상태

이 정리본의 `Package.swift`에는 다음 target을 등록했습니다.

- `WWS2Core`
- `WWS2BLE`
- `WWS2CoreTests`
- `WWS2BLETests`

주의:

- `Sources/WWS2iOSApp`는 유지되어 있지만, 현재 `Package.swift` target에는 일부러 넣지 않았습니다.
- 이유는 SwiftUI `@main App` 구조는 실제 Xcode iOS App target에서 연결하는 편이 더 안전하기 때문입니다.
- Mac에서 Core/BLE 빌드가 먼저 통과하면, 그 다음에 iOS App target을 만들고 `Sources/WWS2iOSApp` 또는 `iOSApp` 코드를 연결하세요.

## 권장 검증 순서

1. Mac에 이 폴더 복사
2. Terminal에서 이 폴더로 이동
3. `swift test` 실행
4. Core/BLE 컴파일 에러 수정
5. Xcode에서 `Package.swift` 열기
6. iOS App target 생성
7. Bluetooth permission/capability 설정
8. 실제 iPhone에서 BLE scan/connect/pairing 테스트

자세한 순서는 `BUILD_CHECKLIST.md`를 보세요.
