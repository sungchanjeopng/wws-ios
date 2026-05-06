import Foundation
import Combine
import WWS2BLE
import WWS2Core

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedTab: AppTab
    @Published private(set) var discoveredDevices: [BleDeviceIdentity]
    @Published private(set) var isBluetoothReady: Bool

    let session: DeviceSessionViewModel

    private let bleManager: BleCentralManager?
    private let pairingManager: PairingManager
    private let otaUploadManager: OtaUploadManager
    private var cancellables: Set<AnyCancellable> = []

    init(
        bleManager: BleCentralManager? = nil,
        session: DeviceSessionViewModel = DeviceSessionViewModel(),
        pairingManager: PairingManager = PairingManager(),
        otaUploadManager: OtaUploadManager = OtaUploadManager(),
        selectedTab: AppTab = .main,
        discoveredDevices: [BleDeviceIdentity] = [],
        isBluetoothReady: Bool = false
    ) {
        self.bleManager = bleManager
        self.session = session
        self.pairingManager = pairingManager
        self.otaUploadManager = otaUploadManager
        self.selectedTab = selectedTab
        self.discoveredDevices = discoveredDevices
        self.isBluetoothReady = isBluetoothReady

        bindSession()
        bindBLE()
    }

    static func live() -> AppViewModel {
        AppViewModel(bleManager: BleCentralManager())
    }

    var isConnected: Bool { session.isConnected }
    var pairingState: PairingState { session.pairingState }
    var downloadState: TransferState { session.downloadState }
    var uploadState: TransferState { session.uploadState }
    var currentReading: DeviceReading? { session.mainReadingState.value }
    var latestEcho: EchoReading? { session.echoReadingState.value }
    var trendRecords: [TrendRecord] { session.trendReadingState.value ?? [] }
    var densityDiag: DiagReading? {
        guard case let .loaded(.density(value)) = session.diagnosticsReadingState else { return nil }
        return value
    }
    var interfaceDiag: InterfaceDiagReading? {
        guard case let .loaded(.interface(value)) = session.diagnosticsReadingState else { return nil }
        return value
    }
    var lastEventMessage: String { session.lastProtocolEventSummary }
    var exportPreviewText: String {
        if !trendRecords.isEmpty { return CSVBuilder.makeTrendRecordsCSV(trendRecords) }
        if let currentReading { return CSVBuilder.makeDeviceReadingCSV(currentReading) }
        return ""
    }

    func startScan() {
        guard let bleManager else {
            session.beginScan()
            return
        }

        guard isBluetoothReady else {
            session.setError("Bluetooth is not powered on. Enable Bluetooth on iPhone before scanning.")
            return
        }

        session.beginScan()
        bleManager.startScan()
    }

    func stopScan() {
        bleManager?.stopScan()
        session.stopScan()
    }

    func requestPairing(pin: Int = 0) {
        guard let device = session.activeDevice else {
            session.setError("Select a WESSWARE device before requesting pairing.")
            return
        }
        guard let bleSession = bleManager?.session(id: device.peripheralIdentifier) else {
            session.setError("BLE session is not ready yet. Connect and wait for service discovery.")
            return
        }
        if bleSession.writeDeviceInfoRequest(pin: pin, withoutResponse: true) {
            session.markTransportReady(maximumWriteLength: bleSession.maximumWriteLength(withoutResponse: true))
        } else {
            session.setError("Write characteristic is not ready. Verify WESSWARE write UUID.")
        }
    }

    func beginDownloadPlaceholder() { prepareDownloadPlaceholder() }
    func beginUploadPlaceholder() { prepareUploadPlaceholder() }

    func connect(to device: BleDeviceIdentity) {
        guard let bleManager else {
            session.beginConnecting(to: device)
            return
        }

        guard isBluetoothReady else {
            session.setError("Bluetooth is not powered on. Enable Bluetooth on iPhone before connecting.")
            return
        }

        session.beginConnecting(to: device)
        bleManager.stopScan()
        bleManager.connect(id: device.peripheralIdentifier)
    }

    func disconnectActiveDevice() {
        guard let activeDevice = session.activeDevice else { return }
        bleManager?.disconnect(id: activeDevice.peripheralIdentifier)
        session.markDisconnected(message: "Disconnect requested for \(session.deviceDisplayName).")
    }

    func prepareDownloadPlaceholder() {
        let deviceName = session.pairingState == .paired ? session.deviceDisplayName : "a paired device"
        session.setDownloadState(
            TransferState(
                phase: .ready,
                title: "Download Flow Not Yet Implemented",
                message: "Use \(deviceName) to validate trend/history paging, export format, and completion rules on a real iPhone.",
                progress: nil
            )
        )
    }

    func simulateDownloadProgress() {
        session.setDownloadState(
            TransferState(
                phase: .transferring,
                title: "Download Placeholder Running",
                message: "Placeholder only. Real download chunks must come from verified device frames.",
                progress: 0.35
            )
        )
    }

    func resetDownloadPlaceholder() {
        session.setDownloadState(.downloadPlaceholder)
    }

    func prepareUploadPlaceholder() {
        let maximumWriteLength = session.maximumWriteWithoutResponse ?? 182
        let chunkSize = otaUploadManager.chunkSize(maximumWriteLength: maximumWriteLength)
        session.setUploadState(
            TransferState(
                phase: .ready,
                title: "Upload Flow Not Yet Implemented",
                message: "Do not assume Android MTU 247. Current placeholder chunk budget is \(chunkSize) bytes from maximumWriteValueLength(for:).",
                progress: nil
            )
        )
    }

    func simulateUploadProgress() {
        session.setUploadState(
            TransferState(
                phase: .transferring,
                title: "Upload Placeholder Running",
                message: "Placeholder only. Real OTA requires verified UUIDs, ACK/error handling, and hardware validation.",
                progress: 0.2
            )
        )
    }

    func resetUploadPlaceholder() {
        session.setUploadState(.uploadPlaceholder)
    }

    private func bindSession() {
        session.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func bindBLE() {
        guard let bleManager else { return }

        bleManager.discoveredPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                guard let self else { return }
                self.discoveredDevices = devices.sorted { $0.displayName < $1.displayName }
                self.session.refreshActiveDevice(from: self.discoveredDevices)
            }
            .store(in: &cancellables)

        bleManager.isBluetoothReadyPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ready in
                guard let self else { return }
                self.isBluetoothReady = ready
                if !ready, self.session.pairingState == .scanning || self.session.pairingState == .connecting {
                    self.session.setError("Bluetooth became unavailable during pairing.")
                }
            }
            .store(in: &cancellables)

        bleManager.onConnectionStateChanged = { [weak self] id, isConnected, error in
            Task { @MainActor in
                self?.handleConnectionState(id: id, isConnected: isConnected, error: error)
            }
        }

        bleManager.onSessionReady = { [weak self] id in
            Task { @MainActor in
                self?.handleSessionReady(id: id)
            }
        }

        bleManager.onSessionEvent = { [weak self] id, event in
            Task { @MainActor in
                self?.handleSessionEvent(id: id, event: event)
            }
        }
    }

    private func handleConnectionState(id: UUID, isConnected: Bool, error: Error?) {
        guard session.activeDevice?.peripheralIdentifier == id else { return }

        if isConnected {
            session.markConnected()
            return
        }

        if let error {
            session.setError("BLE connection ended: \(error.localizedDescription)")
        } else {
            session.markDisconnected()
        }
    }

    private func handleSessionReady(id: UUID) {
        guard session.activeDevice?.peripheralIdentifier == id else { return }
        guard let bleManager, let bleSession = bleManager.session(id: id) else {
            session.setError("BLE transport became ready without an accessible peripheral session.")
            return
        }

        let maximumWriteLength = bleSession.maximumWriteLength(withoutResponse: true)
        session.markTransportReady(maximumWriteLength: maximumWriteLength)

        // TODO: Confirm the real pairing PIN flow and UUIDs against physical hardware before
        // assuming an automatic device-info request is always valid.
        bleSession.writeDeviceInfoRequest(pin: 0, withoutResponse: true)
    }

    private func handleSessionEvent(id: UUID, event: ProtocolClientEvent) {
        let sourceDevice = discoveredDevices.first(where: { $0.peripheralIdentifier == id }) ?? session.activeDevice
        session.apply(event: event, from: sourceDevice, pairingManager: pairingManager)
    }
}
