import Foundation
import Combine
import WWS2Core

#if canImport(CoreBluetooth)
@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var connectedDevices: [ConnectedDevice] = []
    @Published var scannedDevices: [ScannedDevice] = []
    @Published var pin = "0000"
    @Published var statusMessage = "iOS starter ready"
    @Published var lastReading: DeviceReading?
    @Published var lastEcho: EchoReading?
    @Published var lastDiag: DiagReading?
    @Published var bleError: String?

    let ble = WWS2BluetoothManager()
    private var cancellables = Set<AnyCancellable>()
    private var rxBuffer: [UInt8] = []

    init() {
        ble.$scannedDevices.map { Array($0.values).sorted { $0.rssi > $1.rssi } }.assign(to: &$scannedDevices)
        ble.$lastError.assign(to: &$bleError)
        ble.notifications.receive(on: DispatchQueue.main).sink { [weak self] bytes in self?.handleRx(bytes) }.store(in: &cancellables)
    }

    func startScan() { ble.startScan(); statusMessage = "Scanning nearby WESSWARE devices" }
    func stopScan() { ble.stopScan() }
    func connect(_ device: ScannedDevice) { ble.connect(device.id) }
    func disconnect() { ble.disconnect(); connectedDevices.removeAll() }

    func sendPairingRequest() {
        let p = Int(pin) ?? 0
        ble.write(FrameCodec.buildDeviceInfoRequest(pin: p), withoutResponse: false)
    }

    func requestStatus(page: Int = Command.pageStatus) {
        ble.write(FrameCodec.buildHeartbeat(pageIndex: page), withoutResponse: true)
    }

    private func handleRx(_ bytes: [UInt8]) {
        rxBuffer += bytes
        // 우선 단일 프레임 단위 파싱. 실제 장비에서 stream 분리 로직은 추가 검증 필요.
        if let parsed = FrameCodec.parseFrame(rxBuffer) {
            apply(parsed)
            rxBuffer.removeAll()
        } else if rxBuffer.count > 4096 {
            rxBuffer.removeAll()
        }
    }

    private func apply(_ frame: ParsedFrame) {
        let isInterface = connectedDevices.first?.type == .interface
        guard let result = FrameParser.parse(cmd: frame.cmd, data: frame.data, isInterface: isInterface) else { return }
        switch result {
        case .status4B(let reading): lastReading = reading
        case .densityStatus(let reading, _, _, _, _, _, _, _): lastReading = reading
        case .interfaceStatus(let reading, _, _, _, _, _, _, _, _, _, _, _): lastReading = reading
        case .densityEcho(let echo, _, _, _): lastEcho = echo
        case .densityDiag(let diag): lastDiag = diag
        case .interfaceDiag: break
        }
    }
}
#else
final class AppViewModel: ObservableObject {}
#endif
