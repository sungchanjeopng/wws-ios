import Foundation
import WWS2BLE
import WWS2Core

enum FakePreviewData {
    static func appViewModel(selectedTab: AppTab = .main) -> AppViewModel {
        let device = previewDevices[0]
        let session = DeviceSessionViewModel(
            pairingState: .paired,
            pairingMessage: "Paired with \(previewIdentity.displayName).",
            activeDevice: device,
            resolvedIdentity: previewIdentity,
            lastPairingResult: .success(previewDeviceInfo),
            maximumWriteWithoutResponse: 182,
            mainReadingState: .loaded(
                DeviceReading(
                    level: 1.43,
                    heavyLevel: 1.37,
                    temperature: 24.6,
                    currentMA: 12.34,
                    damping: 6,
                    set4mA: 0.40,
                    set20mA: 2.00,
                    pipeDia: 1,
                    freqMHz: 0.380,
                    errorCode: 0,
                    eeaR: 412,
                    eeaD: 389
                )
            ),
            echoReadingState: .loaded(previewEcho),
            trendReadingState: .loaded(previewTrendRecords),
            diagnosticsReadingState: .loaded(.interface(previewInterfaceDiagnostics)),
            downloadState: TransferState(
                phase: .ready,
                title: "Download Preview",
                message: "Preview state only. Real trend export still needs device validation.",
                progress: nil
            ),
            uploadState: TransferState(
                phase: .ready,
                title: "Upload Preview",
                message: "Preview state only. Real OTA must derive chunk sizes from maximumWriteValueLength(for:).",
                progress: nil
            ),
            lastProtocolEventSummary: "Preview loaded from fake state."
        )

        return AppViewModel(
            bleManager: nil,
            session: session,
            selectedTab: selectedTab,
            discoveredDevices: previewDevices,
            isBluetoothReady: true
        )
    }

    static let previewDevices: [BleDeviceIdentity] = [
        BleDeviceIdentity(
            peripheralIdentifier: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1") ?? UUID(),
            advertisedName: "W3A01B02",
            rssi: -51,
            serviceUUIDs: ["FFF0"]
        ),
        BleDeviceIdentity(
            peripheralIdentifier: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE2") ?? UUID(),
            advertisedName: "W2C03",
            rssi: -67,
            serviceUUIDs: ["FFF0"]
        )
    ]

    static let previewDeviceInfo = DeviceInfo(
        siteNameHi: "A",
        siteNameLo: 1,
        ch2SiteNameHi: "B",
        ch2SiteNameLo: 2,
        fwVersion: FwVersion(1, 8, 0),
        serialNumber: "ENV130-0007"
    )

    static let previewIdentity = ResolvedPeripheralIdentity(
        id: previewDevices[0].id,
        peripheralIdentifier: previewDevices[0].peripheralIdentifier,
        protocolIdentityKey: "ENV130:SERIAL:ENV130-0007",
        advertisedName: previewDevices[0].advertisedName,
        displayName: "ENV130  A01 / B02",
        productName: "ENV130",
        ch1SiteName: "A01",
        ch2SiteName: "B02",
        isInterface: true,
        serviceUUIDs: previewDevices[0].serviceUUIDs,
        manufacturerData: previewDevices[0].manufacturerData,
        deviceInfo: previewDeviceInfo
    )

    static let previewEcho = EchoReading(
        eeaR: 412,
        eeaD: 389,
        level: 143,
        detAreaLO: 12,
        detAreaHI: 92,
        pipeDia: 1,
        rawWave: Array(repeating: 180, count: EchoReading.rawWaveSampleCount),
        wave: Array(repeating: 180.0, count: EchoReading.interpolatedWaveSampleCount),
        sampleUs: 2.0,
        thrLightDist: 56,
        thrHeavyDist: 61,
        thrLightAmp: 120,
        thrHeavyAmp: 160
    )

    static let previewInterfaceDiagnostics = InterfaceDiagReading(
        temperature: 24.6,
        currentMA: 12.34,
        freq: 0,
        offset: 0.12,
        set4mA: 0.40,
        set20mA: 2.00,
        tvg: 75,
        damp: 6,
        asf: 3,
        relayOn: true,
        errorCode: 0
    )

    static let previewTrendRecords: [TrendRecord] = [
        TrendRecord(
            dateTime: DateComponents(year: 2026, month: 5, day: 4, hour: 16, minute: 0, second: 0),
            eeaD: 388,
            dst: 141,
            temperature: 24.2,
            step: 1,
            vca: 10,
            status: 0
        ),
        TrendRecord(
            dateTime: DateComponents(year: 2026, month: 5, day: 4, hour: 16, minute: 5, second: 0),
            eeaD: 389,
            dst: 143,
            temperature: 24.6,
            step: 2,
            vca: 10,
            status: 0
        ),
        TrendRecord(
            dateTime: DateComponents(year: 2026, month: 5, day: 4, hour: 16, minute: 10, second: 0),
            eeaD: 390,
            dst: 144,
            temperature: 24.8,
            step: 3,
            vca: 10,
            status: 0
        )
    ]
}
