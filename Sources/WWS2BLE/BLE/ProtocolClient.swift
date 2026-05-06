import Foundation
import WWS2Core

public enum ProtocolClientParseResult: Equatable, Sendable {
    case pairing(PairingResult)
    case status(FrameParser.ParseResult)
    case diagnostics(FrameParser.ParseResult)
}

public enum ProtocolClientEvent: Equatable, Sendable {
    case rawFrame(ParsedFrame)
    case pairingResult(PairingResult)
    case statusResult(FrameParser.ParseResult)
    case diagnosticResult(FrameParser.ParseResult)
    case parsedMeasurement(FrameParser.ParseResult)
}

/// Stateless frame helpers already live in WWS2Core. This client owns the incremental assembler
/// and turns notification chunks into higher-level events that an iOS view model can consume.
///
/// iOS cannot expose the BLE MAC address, so app-level identity must be resolved from the
/// `CBPeripheral.identifier`, advertisement metadata, and the later `DeviceInfo` pairing response.
/// This helper intentionally does not require real service/characteristic UUIDs yet.
public final class ProtocolClient {
    private let assembler: FrameAssembler

    public var isInterface: Bool

    public init(isInterface: Bool = false, maxFrameSize: Int = 4096) {
        self.isInterface = isInterface
        self.assembler = FrameAssembler(maxFrameSize: maxFrameSize)
    }

    public func reset() {
        assembler.reset()
    }

    public func buildPairingRequest(pin: Int = 0) -> [UInt8] {
        FrameCodec.buildDeviceInfoRequest(pin: pin)
    }

    /// Page polling currently uses the same heartbeat frame shape as the Android implementation.
    public func buildPageRequest(pageIndex: Int, expectedLength: Int = 0) -> [UInt8] {
        buildHeartbeatRequest(pageIndex: pageIndex, expectedLength: expectedLength)
    }

    public func buildHeartbeatRequest(pageIndex: Int, expectedLength: Int = 0) -> [UInt8] {
        FrameCodec.buildHeartbeat(pageIndex: pageIndex, expectedLen: expectedLength)
    }

    public func makeDeviceInfoRequest(pin: Int = 0) -> [UInt8] {
        buildPairingRequest(pin: pin)
    }

    public func makeHeartbeat(pageIndex: Int, expectedLength: Int = 0) -> [UInt8] {
        buildHeartbeatRequest(pageIndex: pageIndex, expectedLength: expectedLength)
    }

    public func parsePairingResult(from frame: ParsedFrame) -> PairingResult? {
        guard frame.cmd == Command.deviceInfo else { return nil }
        return FrameCodec.parsePairingPayload(frame.data)
    }

    public func parseStatusResult(from frame: ParsedFrame) -> FrameParser.ParseResult? {
        guard isStatusCommand(frame.cmd) else { return nil }
        guard let result = FrameParser.parse(cmd: frame.cmd, data: frame.data, isInterface: isInterface) else {
            return nil
        }
        return isStatusResult(result) ? result : nil
    }

    public func parseDiagnosticResult(from frame: ParsedFrame) -> FrameParser.ParseResult? {
        guard isDiagnosticCommand(frame.cmd) else { return nil }
        guard let result = FrameParser.parse(cmd: frame.cmd, data: frame.data, isInterface: isInterface) else {
            return nil
        }
        return isDiagnosticResult(result) ? result : nil
    }

    public func parseFrameResult(from frame: ParsedFrame) -> ProtocolClientParseResult? {
        if let pairing = parsePairingResult(from: frame) {
            return .pairing(pairing)
        }
        if let status = parseStatusResult(from: frame) {
            return .status(status)
        }
        if let diagnostics = parseDiagnosticResult(from: frame) {
            return .diagnostics(diagnostics)
        }
        return nil
    }

    public func handleNotificationChunk(_ chunk: [UInt8]) -> [ProtocolClientEvent] {
        assembler.append(chunk).flatMap(handleFrame)
    }

    public func handleFrame(_ frame: ParsedFrame) -> [ProtocolClientEvent] {
        var events: [ProtocolClientEvent] = [.rawFrame(frame)]

        if let pairingResult = parsePairingResult(from: frame) {
            events.append(.pairingResult(pairingResult))
            return events
        }

        if let parsed = FrameParser.parse(cmd: frame.cmd, data: frame.data, isInterface: isInterface) {
            events.append(.parsedMeasurement(parsed))
            if isStatusResult(parsed) {
                events.append(.statusResult(parsed))
            }
            if isDiagnosticResult(parsed) {
                events.append(.diagnosticResult(parsed))
            }
        }

        return events
    }

    private func isStatusCommand(_ cmd: Int) -> Bool {
        cmd == Command.status || cmd == Command.statusCH2
    }

    private func isDiagnosticCommand(_ cmd: Int) -> Bool {
        cmd == Command.diag || cmd == Command.diagCH2
    }

    private func isStatusResult(_ result: FrameParser.ParseResult) -> Bool {
        switch result {
        case .status4B, .densityStatus, .interfaceStatus:
            return true
        default:
            return false
        }
    }

    private func isDiagnosticResult(_ result: FrameParser.ParseResult) -> Bool {
        switch result {
        case .densityDiag, .interfaceDiag:
            return true
        default:
            return false
        }
    }
}
