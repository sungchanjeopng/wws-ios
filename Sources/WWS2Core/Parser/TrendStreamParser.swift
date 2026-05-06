import Foundation

public enum TrendStreamEvent: Equatable, Sendable {
    case header(totalRecords: Int)
    case records([TrendRecord])
    case completed
    case crcFailure(reason: String)
}

/// Stateful parser for trend/download record streams.
/// TODO: Validate against real WESSWARE RX hex captures from iPhone notifications.
public final class TrendStreamParser {
    private enum StreamState: Int {
        case idle = 0
        case waitingHeader = 1
        case receivingChunks = 2
    }

    private static let recordSize = 24

    private var buffer: [UInt8] = []
    private var streamState: StreamState = .idle
    private var runningCRC: UInt16 = 0xFFFF

    public private(set) var totalRecords: Int = 0
    public var retryCount: Int = 0
    public var firstVisit: Bool = true

    public init() {}

    public var isActive: Bool {
        streamState != .idle
    }

    public func startStream() {
        buffer.removeAll()
        streamState = .waitingHeader
        totalRecords = 0
        runningCRC = 0xFFFF
        retryCount = 0
    }

    public func reset() {
        buffer.removeAll()
        streamState = .idle
        totalRecords = 0
        runningCRC = 0xFFFF
        retryCount = 0
        firstVisit = true
    }

    public func append(_ chunk: [UInt8], downloadedCount: Int) -> [TrendStreamEvent] {
        buffer.append(contentsOf: chunk)

        var events: [TrendStreamEvent] = []
        if streamState == .waitingHeader {
            events.append(contentsOf: parseHeader())
        }
        if streamState == .receivingChunks {
            events.append(contentsOf: parseChunks(downloadedCount: downloadedCount))
        }
        return events
    }

    private func parseHeader() -> [TrendStreamEvent] {
        while buffer.count >= 7 {
            if let sofIndex = buffer.firstIndex(of: FrameCodec.sof), sofIndex > 0 {
                buffer.removeFirst(sofIndex)
            } else if buffer.first != FrameCodec.sof {
                buffer.removeAll()
                return []
            }

            guard buffer.count >= 7 else { return [] }

            let command = (Int(buffer[1]) << 8) | Int(buffer[2])
            let validCommands = [Command.trend, Command.trendCH2, Command.download, Command.downloadCH2]
            guard validCommands.contains(command) else {
                buffer.removeFirst()
                continue
            }

            let header = Array(buffer[0..<5])
            let calculatedCRC = Crc.crc16Modbus(header)
            let receivedCRC = UInt16(buffer[5]) | (UInt16(buffer[6]) << 8)
            guard calculatedCRC == receivedCRC else {
                streamState = .idle
                return [.crcFailure(reason: "header CRC FAIL")]
            }

            totalRecords = (Int(buffer[3]) << 8) | Int(buffer[4])
            buffer.removeFirst(7)
            runningCRC = 0xFFFF
            streamState = .receivingChunks
            return [.header(totalRecords: totalRecords)]
        }

        return []
    }

    private func parseChunks(downloadedCount: Int) -> [TrendStreamEvent] {
        var newRecords: [TrendRecord] = []

        while downloadedCount + newRecords.count < totalRecords, buffer.count >= Self.recordSize {
            let recordBytes = Array(buffer.prefix(Self.recordSize))
            buffer.removeFirst(Self.recordSize)

            for byte in recordBytes {
                runningCRC = Crc.crc16Update(runningCRC, byte: byte)
            }

            if let record = TrendRecord.fromBytes(recordBytes) {
                newRecords.append(record)
            }
        }

        var events: [TrendStreamEvent] = []
        if !newRecords.isEmpty {
            events.append(.records(newRecords))
        }

        if downloadedCount + newRecords.count >= totalRecords {
            guard buffer.count >= 2 else { return events }

            let receivedCRC = UInt16(buffer[0]) | (UInt16(buffer[1]) << 8)
            buffer.removeFirst(2)

            guard receivedCRC == runningCRC else {
                streamState = .idle
                events.append(.crcFailure(reason: "final CRC FAIL"))
                return events
            }

            streamState = .idle
            events.append(.completed)
        }

        return events
    }
}
