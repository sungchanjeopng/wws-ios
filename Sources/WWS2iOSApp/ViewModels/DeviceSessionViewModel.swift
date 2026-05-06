import Foundation
import Combine
import WWS2BLE
import WWS2Core

enum PairingState: String, Equatable {
    case idle
    case scanning
    case connecting
    case pairing
    case paired
    case error

    var title: String {
        rawValue.capitalized
    }

    var label: String {
        switch self {
        case .idle: return "Idle"
        case .scanning: return "Scanning"
        case .connecting: return "Connecting"
        case .pairing: return "Pairing"
        case .paired: return "Paired"
        case .error: return "Error"
        }
    }
}

enum ReadingState<Value: Equatable>: Equatable {
    case idle(String)
    case waiting(String)
    case loaded(Value)
    case error(String)

    var statusText: String {
        switch self {
        case let .idle(message), let .waiting(message), let .error(message):
            return message
        case .loaded:
            return "Live data available."
        }
    }

    var value: Value? {
        guard case let .loaded(value) = self else { return nil }
        return value
    }
}

struct TransferState: Equatable {
    enum Phase: String, Equatable {
        case idle
        case ready
        case transferring
        case completed
        case error
    }

    var phase: Phase
    var title: String
    var message: String
    var progress: Double?

    static var downloadPlaceholder: TransferState {
        TransferState(
            phase: .idle,
            title: "Download Placeholder",
            message: "Trend/history download commands, paging, and export still need real WESSWARE hardware validation.",
            progress: nil
        )
    }

    static var uploadPlaceholder: TransferState {
        TransferState(
            phase: .idle,
            title: "Upload Placeholder",
            message: "OTA upload still needs verified BLE UUIDs, maximumWriteValueLength sizing, and real iPhone/device testing.",
            progress: nil
        )
    }

    var label: String {
        if let progress {
            return "\(title) - \(Int(progress * 100))%"
        }
        return "\(title): \(message)"
    }
}

enum DiagnosticsSnapshot: Equatable {
    case density(DiagReading)
    case interface(InterfaceDiagReading)

    var title: String {
        switch self {
        case .density:
            return "Density Diagnostics"
        case .interface:
            return "Interface Diagnostics"
        }
    }
}

@MainActor
final class DeviceSessionViewModel: ObservableObject {
    @Published private(set) var pairingState: PairingState
    @Published private(set) var pairingMessage: String
    @Published private(set) var activeDevice: BleDeviceIdentity?
    @Published private(set) var resolvedIdentity: ResolvedPeripheralIdentity?
    @Published private(set) var lastPairingResult: PairingResult?
    @Published private(set) var maximumWriteWithoutResponse: Int?
    @Published private(set) var mainReadingState: ReadingState<DeviceReading>
    @Published private(set) var echoReadingState: ReadingState<EchoReading>
    @Published private(set) var trendReadingState: ReadingState<[TrendRecord]>
    @Published private(set) var diagnosticsReadingState: ReadingState<DiagnosticsSnapshot>
    @Published private(set) var downloadState: TransferState
    @Published private(set) var uploadState: TransferState
    @Published private(set) var lastProtocolEventSummary: String

    init(
        pairingState: PairingState = .idle,
        pairingMessage: String = "No active BLE session.",
        activeDevice: BleDeviceIdentity? = nil,
        resolvedIdentity: ResolvedPeripheralIdentity? = nil,
        lastPairingResult: PairingResult? = nil,
        maximumWriteWithoutResponse: Int? = nil,
        mainReadingState: ReadingState<DeviceReading> = .idle("Connect to request a status frame."),
        echoReadingState: ReadingState<EchoReading> = .idle("Connect to request an echo frame."),
        trendReadingState: ReadingState<[TrendRecord]> = .idle("Trend data has not been requested."),
        diagnosticsReadingState: ReadingState<DiagnosticsSnapshot> = .idle("Diagnostics are waiting for a live session."),
        downloadState: TransferState = .downloadPlaceholder,
        uploadState: TransferState = .uploadPlaceholder,
        lastProtocolEventSummary: String = "No BLE protocol frames received yet."
    ) {
        self.pairingState = pairingState
        self.pairingMessage = pairingMessage
        self.activeDevice = activeDevice
        self.resolvedIdentity = resolvedIdentity
        self.lastPairingResult = lastPairingResult
        self.maximumWriteWithoutResponse = maximumWriteWithoutResponse
        self.mainReadingState = mainReadingState
        self.echoReadingState = echoReadingState
        self.trendReadingState = trendReadingState
        self.diagnosticsReadingState = diagnosticsReadingState
        self.downloadState = downloadState
        self.uploadState = uploadState
        self.lastProtocolEventSummary = lastProtocolEventSummary
    }

    var isConnected: Bool {
        pairingState == .pairing || pairingState == .paired
    }

    var deviceDisplayName: String {
        resolvedIdentity?.displayName ?? activeDevice?.displayName ?? "No Device"
    }

    var topBarSubtitle: String {
        if let identity = resolvedIdentity {
            if let budget = maximumWriteWithoutResponse {
                return "\(identity.displayName) | TX \(budget) bytes"
            }
            return identity.displayName
        }

        if let activeDevice {
            return "\(activeDevice.displayName) | \(pairingState.title)"
        }

        return pairingMessage
    }

    func beginScan() {
        pairingState = .scanning
        pairingMessage = "Scanning for WESSWARE BLE advertisements."
        lastProtocolEventSummary = "Waiting for scan results."
        if !isConnected {
            activeDevice = nil
            resolvedIdentity = nil
            lastPairingResult = nil
            maximumWriteWithoutResponse = nil
            resetMeasurements()
            resetTransfers()
        }
    }

    func stopScan() {
        if pairingState == .scanning {
            pairingState = .idle
            pairingMessage = "Scan stopped."
        }
    }

    func beginConnecting(to device: BleDeviceIdentity) {
        activeDevice = device
        resolvedIdentity = nil
        lastPairingResult = nil
        maximumWriteWithoutResponse = nil
        pairingState = .connecting
        pairingMessage = "Connecting to \(device.displayName)."
        lastProtocolEventSummary = "Connection requested for \(device.advertisedName)."
        resetMeasurements()
        resetTransfers()
    }

    func refreshActiveDevice(from devices: [BleDeviceIdentity]) {
        guard let current = activeDevice else { return }
        activeDevice = devices.first(where: { $0.peripheralIdentifier == current.peripheralIdentifier }) ?? current
    }

    func markConnected() {
        pairingState = .pairing
        pairingMessage = "Connected. Discovering services and characteristics."
    }

    func markTransportReady(maximumWriteLength: Int) {
        maximumWriteWithoutResponse = maximumWriteLength
        pairingState = .pairing
        pairingMessage = "Transport ready. Device info request can use up to \(maximumWriteLength) bytes per write without response."
    }

    func markDisconnected(message: String = "Disconnected.") {
        pairingState = .idle
        pairingMessage = message
        maximumWriteWithoutResponse = nil
        lastProtocolEventSummary = "BLE session closed."
    }

    func setError(_ message: String) {
        pairingState = .error
        pairingMessage = message
        lastProtocolEventSummary = message
    }

    func setDownloadState(_ state: TransferState) {
        downloadState = state
    }

    func setUploadState(_ state: TransferState) {
        uploadState = state
    }

    func resetTransfers() {
        downloadState = .downloadPlaceholder
        uploadState = .uploadPlaceholder
    }

    func apply(event: ProtocolClientEvent, from sourceDevice: BleDeviceIdentity?, pairingManager: PairingManager) {
        switch event {
        case let .rawFrame(frame):
            lastProtocolEventSummary = String(
                format: "Received frame 0x%04X (%d bytes payload).",
                frame.cmd,
                frame.data.count
            )

        case let .pairingResult(result):
            applyPairingResult(result, from: sourceDevice, pairingManager: pairingManager)

        case .statusResult, .diagnosticResult:
            break

        case let .parsedMeasurement(result):
            applyParseResult(result)
        }
    }

    private func applyPairingResult(
        _ result: PairingResult,
        from sourceDevice: BleDeviceIdentity?,
        pairingManager: PairingManager
    ) {
        lastPairingResult = result

        guard let sourceDevice = sourceDevice ?? activeDevice else {
            setError("Pairing response arrived without a known peripheral context.")
            return
        }

        switch result {
        case .pinFailed:
            setError("Device rejected the current pairing PIN.")

        case .success:
            let identity = pairingManager.resolveIdentity(
                peripheralIdentifier: sourceDevice.peripheralIdentifier,
                advertisedName: sourceDevice.advertisedName,
                serviceUUIDs: sourceDevice.serviceUUIDs,
                manufacturerData: sourceDevice.manufacturerData,
                pairingResult: result
            )
            activeDevice = sourceDevice
            resolvedIdentity = identity
            pairingState = .paired
            pairingMessage = "Paired with \(identity.displayName)."
            prepareForLiveFrames()
        }
    }

    private func applyParseResult(_ result: FrameParser.ParseResult) {
        switch result {
        case let .status4B(reading):
            mainReadingState = .loaded(reading)
            lastProtocolEventSummary = "Loaded compact status frame."

        case let .densityStatus(reading, trendRecord, relay, densUnit, _, _, _, _):
            mainReadingState = .loaded(reading)
            appendTrendRecord(trendRecord)
            lastProtocolEventSummary = "Loaded density status frame. Relay \(relay), unit \(densUnit)."

        case let .interfaceStatus(
            reading,
            temperature,
            currentMA,
            damping,
            set4mA,
            set20mA,
            freqMHz,
            tvg,
            offset,
            asf,
            relay,
            trendRecord
        ):
            mainReadingState = .loaded(reading)
            appendTrendRecord(trendRecord)
            lastProtocolEventSummary = String(
                format: "Loaded interface status: %.1f C, %.2f mA, relay %d, TVG %d, ASF %d, offset %.2f, 4mA %.2f, 20mA %.2f, %.3f MHz, damp %d.",
                temperature,
                currentMA,
                relay,
                tvg,
                asf,
                offset,
                set4mA,
                set20mA,
                freqMHz,
                damping
            )

        case let .densityEcho(echo, _, trendRecord, densUnit):
            echoReadingState = .loaded(echo)
            appendTrendRecord(trendRecord)
            lastProtocolEventSummary = "Loaded density echo frame. Unit \(densUnit), \(echo.wave.count) interpolated samples."

        case let .densityDiag(diag):
            diagnosticsReadingState = .loaded(.density(diag))
            lastProtocolEventSummary = String(
                format: "Loaded density diagnostics: %.1f C, %.2f mA, err %d.",
                diag.temperature,
                diag.currentMA,
                diag.errorCode
            )

        case let .interfaceDiag(diag):
            diagnosticsReadingState = .loaded(.interface(diag))
            lastProtocolEventSummary = String(
                format: "Loaded interface diagnostics: %.1f C, %.2f mA, err %d.",
                diag.temperature,
                diag.currentMA,
                diag.errorCode
            )
        }
    }

    private func prepareForLiveFrames() {
        mainReadingState = .waiting("Paired. Waiting for a live status frame.")
        echoReadingState = .waiting("Paired. Waiting for a live echo frame.")
        trendReadingState = .waiting("Paired. Waiting for trend samples or trend history pages.")
        diagnosticsReadingState = .waiting("Paired. Waiting for a diagnostics frame.")
    }

    private func appendTrendRecord(_ record: TrendRecord) {
        var records = trendReadingState.value ?? []
        records.append(record)
        trendReadingState = .loaded(Array(records.suffix(24)))
    }

    private func resetMeasurements() {
        mainReadingState = .idle("Connect to request a status frame.")
        echoReadingState = .idle("Connect to request an echo frame.")
        trendReadingState = .idle("Trend data has not been requested.")
        diagnosticsReadingState = .idle("Diagnostics are waiting for a live session.")
    }
}
