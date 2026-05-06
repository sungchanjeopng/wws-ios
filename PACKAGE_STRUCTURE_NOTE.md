# PACKAGE_STRUCTURE_NOTE

이 정리본의 `Package.swift`는 빌드 검증을 쉽게 하기 위해 다음처럼 구성했습니다.

## 등록된 target

```text
WWS2Core
WWS2BLE
WWS2CoreTests
WWS2BLETests
```

## 왜 WWS2iOSApp target은 Package.swift에 넣지 않았나?

`Sources/WWS2iOSApp`에는 SwiftUI 화면과 `@main App` 코드가 있습니다.
이 코드는 유지되어 있지만, Swift Package의 일반 library target으로 넣으면 실제 iOS App target 구조와 충돌하거나 Xcode 연결 방식이 애매해질 수 있습니다.

그래서 우선순위를 이렇게 잡았습니다.

1. `WWS2Core`와 `WWS2BLE`가 Mac에서 컴파일되는지 먼저 확인
2. Core/BLE 테스트 실행
3. 실제 Xcode iOS App project/target을 만든 뒤 SwiftUI 코드를 연결
4. iPhone 실기기 BLE 테스트

## 역할 구분

- `Sources/WWS2Core`
  - 순수 로직 라이브러리
- `Sources/WWS2BLE`
  - CoreBluetooth 기반 BLE 라이브러리
- `Sources/WWS2iOSApp`
  - SwiftUI/ViewModel 코드 보관 위치
- `iOSApp`
  - Xcode에서 실제 앱 target 생성 시 참고하거나 복사할 starter

## Mac 담당자가 선택할 수 있는 방식

### 방식 A: 안전한 방식

1. 이 Package.swift 그대로 `swift test`
2. Core/BLE 에러 수정
3. 별도 Xcode iOS App target 생성
4. `Sources/WWS2iOSApp` 또는 `iOSApp` 파일을 App target에 연결

### 방식 B: Package에 UI target도 추가해서 실험

Mac/Xcode에서 구조를 잘 아는 사람이면 `Sources/WWS2iOSApp`를 별도 target으로 추가해볼 수 있습니다.
다만 이 경우 SwiftUI `@main App` 처리와 실제 app host target 연결 방식을 조정해야 할 수 있습니다.
