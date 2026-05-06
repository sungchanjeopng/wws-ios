# BUILD_CHECKLIST

대상 폴더:

`C:\Users\jeong\Downloads\wws2_ios_ready_for_mac`

이 체크리스트는 Mac/Xcode 환경에서 빌드 검증하는 사람이 그대로 따라 하기 위한 문서입니다.

## 1. 폴더 복사

Windows에서 이 폴더 전체를 Mac으로 복사합니다.

예시 Mac 경로:

```bash
~/Downloads/wws2_ios_ready_for_mac
```

## 2. Swift Package 테스트

Mac Terminal에서 실행:

```bash
cd ~/Downloads/wws2_ios_ready_for_mac
swift test
```

확인할 것:

- `WWS2Core` 컴파일 여부
- `WWS2BLE` 컴파일 여부
- `WWS2CoreTests` 실행 여부
- `WWS2BLETests` 실행 여부

실패하면 다음 정보를 저장하세요.

```bash
swift test 2>&1 | tee swift_test_error.log
```

## 3. Xcode에서 Package 열기

```bash
open Package.swift
```

Xcode에서 확인할 것:

- Package indexing 완료 여부
- `WWS2Core` target 인식 여부
- `WWS2BLE` target 인식 여부
- Test navigator에서 Core/BLE 테스트 표시 여부

## 4. 실제 iOS App target 생성

Swift Package 자체만으로는 TestFlight용 완성 앱이 아닙니다.
실제 앱 설치/테스트를 하려면 Xcode에서 iOS App target이 필요합니다.

권장 절차:

1. Xcode > File > New > Project
2. iOS > App 선택
3. Product Name: `WESSWARE`
4. Interface: SwiftUI
5. Language: Swift
6. Bundle Identifier 예시: `com.wessware.wws2`
7. 생성된 App target에 이 package를 dependency로 추가
8. `Sources/WWS2iOSApp` 또는 `iOSApp`의 SwiftUI/ViewModel 파일을 App target에 연결

## 5. Bluetooth 권한 설정

실제 iOS App target의 `Info.plist`에 추가:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>WESSWARE measurement devices require Bluetooth connection.</string>
```

필요 시 구형 호환용:

```xml
<key>NSBluetoothPeripheralUsageDescription</key>
<string>WESSWARE measurement devices require Bluetooth connection.</string>
```

Background BLE가 필요하면 Xcode Signing & Capabilities에서 Background Modes를 켜고:

- Uses Bluetooth LE accessories / bluetooth-central

단, App Store 심사 사유가 필요할 수 있습니다.

## 6. iPhone 실기기 테스트

Simulator로는 BLE 장비 테스트가 불가능합니다.
실제 iPhone과 WESSWARE 장비가 필요합니다.

최소 확인 순서:

1. 앱 설치
2. Bluetooth 권한 허용
3. scan 시작
4. WESSWARE 장비 발견 여부 확인
5. connect 성공 여부 확인
6. service/characteristic discovery 확인
7. notify subscribe 성공 여부 확인
8. pairing request 전송
9. pairing response 수신
10. status/echo/diag/trend frame 수신 확인

## 7. 에러 발생 시 남길 자료

- `swift_test_error.log`
- Xcode build error 전체 로그
- iPhone console log
- BLE service/write/notify UUID
- 실제 raw hex frame
- 사용한 iPhone 모델/iOS 버전
- WESSWARE 장비 모델/펌웨어 버전
