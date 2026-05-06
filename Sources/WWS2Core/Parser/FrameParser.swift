import Foundation

public enum FrameParseResult: Equatable {
    case status4B(DeviceReading)
    case densityStatus(reading: DeviceReading, trendRecord: TrendRecord, relay: Int, densUnit: Int, extIn1En: Int, extIn1State: Int, extIn2En: Int, extIn2State: Int)
    case interfaceStatus(reading: DeviceReading, temperature: Double, currentMA: Double, damping: Int, set4mA: Double, set20mA: Double, freqMHz: Double, tvg: Int, offset: Double, asf: Int, relay: Int, trendRecord: TrendRecord)
    case densityEcho(echo: EchoReading, temperature: Double, trendRecord: TrendRecord, densUnit: Int)
    case densityDiag(DiagReading)
    case interfaceDiag(InterfaceDiagReading)
}

public enum FrameParser {
    public static func expectedDataSize(cmd: Int, isInterface: Bool) -> Int? {
        switch cmd {
        case 0x0000, 0x0010: return isInterface ? 26 : 34
        case 0x0001: return isInterface ? nil : 224
        case 0x0003: return 30
        case 0x0004, 0x0014: return isInterface ? 22 : 16
        default: return nil
        }
    }

    public static func parse(cmd: Int, data: [UInt8], isInterface: Bool, now: Date = Date()) -> FrameParseResult? {
        if cmd == 0x0000 || cmd == 0x0010 { return parseStatus(data, now: now) }
        if cmd == 0x0001 && data.count == 224 { return parseDensityEcho(data, now: now) }
        if cmd == 0x0004 && data.count == 16, let diag = DiagReading.fromBytes(data) { return .densityDiag(diag) }
        if (cmd == 0x0004 || cmd == 0x0014) && data.count >= 22, let diag = InterfaceDiagReading.fromBytes(data) { return .interfaceDiag(diag) }
        return nil
    }

    private static func parseStatus(_ data: [UInt8], now: Date) -> FrameParseResult? {
        switch data.count {
        case 4: return parseStatus4B(data)
        case 34: return parseDensityStatus34B(data, now: now)
        case 26: return parseInterfaceStatus26B(data, now: now)
        default: return nil
        }
    }

    private static func parseStatus4B(_ data: [UInt8]) -> FrameParseResult? {
        guard data.count == 4 else { return nil }
        let dst = Double((UInt16(data[0]) << 8) | UInt16(data[1])) * 0.01
        let err = Int((UInt16(data[2]) << 8) | UInt16(data[3]))
        let reading = DeviceReading(level: dst, temperature: 0, currentMA: 0, damping: 0, set4mA: 0, set20mA: 0, pipeDia: 0, freqMHz: 0, errorCode: err)
        return .status4B(reading)
    }

    private static func parseDensityStatus34B(_ data: [UInt8], now: Date) -> FrameParseResult? {
        guard data.count == 34 else { return nil }
        var r = ByteReader(data)
        guard let rawDst = r.readUInt16BE(), let eeaD = r.readUInt16BE(), let eeaR = r.readUInt16BE(), let temp = r.readInt16BE(), let cur = r.readUInt16BE(), let damping = r.readUInt16BE(), let s4 = r.readUInt16BE(), let s20 = r.readUInt16BE(), let pipe = r.readUInt16BE(), let freq = r.readUInt16BE(), let err = r.readUInt16BE(), let relay = r.readUInt16BE(), let densUnit = r.readUInt16BE(), let e1en = r.readUInt16BE(), let e1st = r.readUInt16BE(), let e2en = r.readUInt16BE(), let e2st = r.readUInt16BE() else { return nil }
        let dst = Double(rawDst) * 0.01
        let temperature = Double(temp) * 0.1
        let reading = DeviceReading(level: dst, temperature: temperature, currentMA: Double(cur) * 0.01, damping: Int(damping), set4mA: Double(s4) * 0.01, set20mA: Double(s20) * 0.01, pipeDia: Int(pipe), freqMHz: Double(freq) * 0.001, eeaR: Int(eeaR), eeaD: Int(eeaD), errorCode: Int(err))
        let trend = TrendRecord(dateTime: now, eeaD: Int(eeaD), dst: dst, temperature: temperature)
        return .densityStatus(reading: reading, trendRecord: trend, relay: Int(relay), densUnit: Int(densUnit), extIn1En: Int(e1en), extIn1State: Int(e1st), extIn2En: Int(e2en), extIn2State: Int(e2st))
    }

    private static func parseInterfaceStatus26B(_ data: [UInt8], now: Date) -> FrameParseResult? {
        guard data.count == 26 else { return nil }
        var r = ByteReader(data)
        guard let rawLight = r.readUInt16BE(), let rawHeavy = r.readUInt16BE(), let rawTemp = r.readInt16BE(), let rawCur = r.readUInt16BE(), let freqIdx = r.readUInt16BE(), let rawOffset = r.readInt16BE(), let raw4 = r.readUInt16BE(), let raw20 = r.readUInt16BE(), let tvg = r.readUInt16BE(), let damping = r.readUInt16BE(), let asf = r.readUInt16BE(), let relay = r.readUInt16BE(), let err = r.readUInt16BE() else { return nil }
        let light = Double(rawLight) * 0.01
        let heavy = Double(rawHeavy) * 0.01
        let temperature = Double(rawTemp) * 0.1
        let freqKHz: Int = { switch Int(freqIdx) { case 0: return 380; case 1: return 270; case 2: return 160; case 3: return 130; default: return 0 } }()
        let reading = DeviceReading(level: light, temperature: temperature, currentMA: Double(rawCur) * 0.01, damping: Int(damping), set4mA: Double(raw4) * 0.01, set20mA: Double(raw20) * 0.01, pipeDia: 0, freqMHz: Double(freqKHz) * 0.001, heavyLevel: heavy, errorCode: Int(err))
        let trend = TrendRecord(dateTime: now, eeaD: Int(heavy / 0.01), dst: light, temperature: temperature)
        return .interfaceStatus(reading: reading, temperature: temperature, currentMA: Double(rawCur) * 0.01, damping: Int(damping), set4mA: Double(raw4) * 0.01, set20mA: Double(raw20) * 0.01, freqMHz: Double(freqKHz) * 0.001, tvg: Int(tvg), offset: Double(rawOffset) * 0.01, asf: Int(asf), relay: Int(relay), trendRecord: trend)
    }

    private static func parseDensityEcho(_ data: [UInt8], now: Date) -> FrameParseResult? {
        guard data.count == 224 else { return nil }
        let echoData = Array(data[0..<14]) + Array(data[16..<222])
        guard let echo = EchoReading.fromBytes(echoData) else { return nil }
        let rawTemp = UInt16(data[14]) << 8 | UInt16(data[15])
        let temperature = Double(Int16(bitPattern: rawTemp)) * 0.1
        let densUnit = Int((UInt16(data[222]) << 8) | UInt16(data[223]))
        let trend = TrendRecord(dateTime: now, eeaD: echo.eeaD, dst: echo.level, temperature: temperature)
        return .densityEcho(echo: echo, temperature: temperature, trendRecord: trend, densUnit: densUnit)
    }
}
