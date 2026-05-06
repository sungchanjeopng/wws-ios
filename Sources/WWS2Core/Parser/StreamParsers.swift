import Foundation

public final class TrendStreamParser {
    public private(set) var streamState: Int = 0   // 0 idle, 1 header, 2 chunks
    public private(set) var totalRecords: Int = 0
    public var retryCount: Int = 0
    public var firstVisit: Bool = true
    private var runningCrc: UInt16 = 0xFFFF
    public var isActive: Bool { streamState > 0 }

    public init() {}
    public func startStream() { streamState = 1; totalRecords = 0; runningCrc = 0xFFFF; retryCount = 0 }
    public func reset() { streamState = 0; totalRecords = 0; runningCrc = 0xFFFF; firstVisit = true; retryCount = 0 }

    public func tryParse(rxBuffer: inout [UInt8], downloadedCount: Int) -> TrendStreamEvent {
        if streamState == 1 {
            let event = tryParseHeader(rxBuffer: &rxBuffer)
            if event.isTerminal { return event }
        }
        if streamState == 2 { return parseChunks(rxBuffer: &rxBuffer, downloadedCount: downloadedCount) }
        return .none
    }

    private func tryParseHeader(rxBuffer: inout [UInt8]) -> TrendStreamEvent {
        while rxBuffer.count >= 7 {
            guard let sofIdx = FrameCodec.indexOfSubsequence(data: rxBuffer, pattern: [FrameCodec.sof]) else { rxBuffer.removeAll(); return .none }
            if sofIdx > 0 { rxBuffer.removeFirst(sofIdx) }
            if rxBuffer.count < 7 { return .none }
            let cmd = (Int(rxBuffer[1]) << 8) | Int(rxBuffer[2])
            guard [0x0002, 0x0012, 0x0007, 0x0017].contains(cmd) else { rxBuffer.removeFirst(); continue }
            let crcCalc = Crc.crc16Modbus(Array(rxBuffer[0..<5]))
            let crcRecv = UInt16(rxBuffer[5]) | (UInt16(rxBuffer[6]) << 8)
            guard crcCalc == crcRecv else { return .crcFail("header CRC FAIL") }
            totalRecords = (Int(rxBuffer[3]) << 8) | Int(rxBuffer[4])
            rxBuffer.removeFirst(7)
            runningCrc = 0xFFFF
            streamState = 2
            return .header(totalRecords)
        }
        return .none
    }

    private func parseChunks(rxBuffer: inout [UInt8], downloadedCount: Int) -> TrendStreamEvent {
        var newRecords: [TrendRecord] = []
        while downloadedCount + newRecords.count < totalRecords && rxBuffer.count >= 24 {
            let recBytes = Array(rxBuffer[0..<24])
            rxBuffer.removeFirst(24)
            for b in recBytes { runningCrc = Crc.crc16Update(runningCrc, byte: b) }
            if let rec = TrendRecord.fromBytes(recBytes) { newRecords.append(rec) }
        }
        if downloadedCount + newRecords.count >= totalRecords, rxBuffer.count >= 2 {
            let crcReceived = UInt16(rxBuffer[0]) | (UInt16(rxBuffer[1]) << 8)
            rxBuffer.removeFirst(2)
            guard crcReceived == runningCrc else { return .crcFail("final CRC FAIL") }
            streamState = 0
            return .complete(records: newRecords)
        }
        return newRecords.isEmpty ? .none : .records(newRecords)
    }
}

public enum TrendStreamEvent: Equatable {
    case none
    case header(Int)
    case records([TrendRecord])
    case complete(records: [TrendRecord])
    case crcFail(String)
    public var isTerminal: Bool { if case .crcFail = self { return true }; return false }
}

public final class InterfaceEchoParser {
    public private(set) var state: Int = 0
    public private(set) var cmd: Int = 0
    public private(set) var headerData: [UInt8] = []
    private var echoN = 0
    private var fullChunks = 0
    private var chunksDone = 0
    private var wave: [Int] = []
    private var runningCrc: UInt16 = 0xFFFF
    public var isCollecting: Bool { state == 1 }
    public init() {}

    public func beginCollection(headerPacket: [UInt8], parsedCmd: Int) {
        guard headerPacket.count >= 33 else { reset(); return }
        headerData = Array(headerPacket[3..<33])
        let emptyVal = (Int(headerData[6]) << 8) | Int(headerData[7])
        echoN = min(Int(Double(emptyVal) * 1.1), 1100)
        if echoN == 0 { echoN = 1 }
        fullChunks = echoN / 98
        chunksDone = 0; wave.removeAll(); cmd = parsedCmd
        runningCrc = 0xFFFF
        for b in headerPacket[0..<33] { runningCrc = Crc.crc16Update(runningCrc, byte: b) }
        state = 1
    }

    public func tryParseChunks(rxBuffer: inout [UInt8]) -> InterfaceEchoReading? {
        while chunksDone < fullChunks {
            guard rxBuffer.count >= 196 else { return nil }
            for b in rxBuffer[0..<196] { runningCrc = Crc.crc16Update(runningCrc, byte: b) }
            for j in 0..<98 { wave.append((Int(rxBuffer[j * 2]) << 8) | Int(rxBuffer[j * 2 + 1])) }
            rxBuffer.removeFirst(196)
            chunksDone += 1
        }
        let lastSamples = echoN % 98
        let lastSize = lastSamples * 2 + 2
        guard rxBuffer.count >= lastSize else { return nil }
        for j in 0..<lastSamples {
            let b0 = rxBuffer[j * 2], b1 = rxBuffer[j * 2 + 1]
            runningCrc = Crc.crc16Update(runningCrc, byte: b0)
            runningCrc = Crc.crc16Update(runningCrc, byte: b1)
            wave.append((Int(b0) << 8) | Int(b1))
        }
        let recvCrc = UInt16(rxBuffer[lastSamples * 2]) | (UInt16(rxBuffer[lastSamples * 2 + 1]) << 8)
        rxBuffer.removeFirst(lastSize)
        state = 0
        guard runningCrc == recvCrc else { return nil }
        var waveBytes: [UInt8] = []
        for v in wave { waveBytes.append(UInt8((v >> 8) & 0xFF)); waveBytes.append(UInt8(v & 0xFF)) }
        return InterfaceEchoReading.fromBytes(headerData + waveBytes)
    }

    public func reset() { state = 0; wave.removeAll(); headerData.removeAll() }
}
