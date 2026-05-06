import Foundation

public struct TrendRecord: Equatable {
    public let dateTime: Date
    public let eeaD: Int
    public let dst: Double
    public let temperature: Double
    public let step: Int
    public let vca: Int
    public let status: Int
    public let deviceId: String

    public init(dateTime: Date, eeaD: Int, dst: Double, temperature: Double, step: Int = 0, vca: Int = 0, status: Int = 0, deviceId: String = "") {
        self.dateTime = dateTime; self.eeaD = eeaD; self.dst = dst; self.temperature = temperature; self.step = step; self.vca = vca; self.status = status; self.deviceId = deviceId
    }

    public static func fromBytes(_ data: [UInt8], calendar: Calendar = Calendar(identifier: .gregorian)) -> TrendRecord? {
        guard data.count >= 24 else { return nil }
        let year = 2000 + Int(data[1])
        let month = min(max(Int(data[3]), 1), 12)
        let day = min(max(Int(data[5]), 1), 31)
        let hour = min(max(Int(data[7]), 0), 23)
        let minute = min(max(Int(data[9]), 0), 59)
        let second = min(max(Int(data[11]), 0), 59)
        var comps = DateComponents()
        comps.calendar = calendar; comps.year = year; comps.month = month; comps.day = day; comps.hour = hour; comps.minute = minute; comps.second = second
        guard let date = comps.date else { return nil }
        var r = ByteReader(Array(data[12..<24]))
        guard let eeaD = r.readUInt16BE(), let rawDst = r.readUInt16BE(), let rawTemp = r.readInt16BE(), let step = r.readUInt16BE(), let vca = r.readUInt16BE(), let status = r.readUInt16BE() else { return nil }
        return TrendRecord(dateTime: date, eeaD: Int(eeaD), dst: Double(rawDst), temperature: Double(rawTemp) * 0.1, step: Int(step), vca: Int(vca), status: Int(status))
    }
}

public struct DiagReading: Equatable {
    public let temperature: Double
    public let currentMA: Double
    public let damping: Int
    public let set4mA: Double
    public let set20mA: Double
    public let pipeDia: Int
    public let freqMHz: Double

    public static func fromBytes(_ data: [UInt8]) -> DiagReading? {
        guard data.count == 16 else { return nil }
        var r = ByteReader(data)
        guard let rawTemp = r.readInt16BE(), let rawCurrent = r.readUInt16BE(), let rawDamping = r.readUInt16BE(), let raw4 = r.readUInt16BE(), let raw20 = r.readUInt16BE(), let rawPipe = r.readUInt16BE(), let rawFreq = r.readUInt16BE(), let _ = r.readUInt16BE() else { return nil }
        return DiagReading(temperature: Double(rawTemp) * 0.1, currentMA: Double(rawCurrent) * 0.01, damping: Int(rawDamping), set4mA: Double(raw4) * 0.01, set20mA: Double(raw20) * 0.01, pipeDia: Int(rawPipe), freqMHz: Double(rawFreq) * 0.001)
    }
}

public struct InterfaceDiagReading: Equatable {
    public let temperature: Double
    public let currentMA: Double
    public let freq: Int
    public let offset: Double
    public let set4mA: Double
    public let set20mA: Double
    public let tvg: Int
    public let damp: Int
    public let asf: Int
    public let relayOn: Bool

    public var freqLabel: String { switch freq { case 0: return "130K"; case 1: return "160K"; case 2: return "270K"; case 3: return "380K"; default: return "--" } }

    public static func fromBytes(_ data: [UInt8]) -> InterfaceDiagReading? {
        guard data.count >= 22 else { return nil }
        var r = ByteReader(data)
        guard let rawTemp = r.readInt16BE(), let rawCurrent = r.readUInt16BE(), let rawFreq = r.readUInt16BE(), let rawOffset = r.readInt16BE(),
              let raw4 = r.readUInt16BE(), let raw20 = r.readUInt16BE(), let rawTvg = r.readUInt16BE(), let rawDamp = r.readUInt16BE(), let rawAsf = r.readUInt16BE(), let rawRelay = r.readUInt16BE(), let _ = r.readUInt16BE() else { return nil }
        return InterfaceDiagReading(temperature: Double(rawTemp) * 0.1, currentMA: Double(rawCurrent) * 0.01, freq: Int(rawFreq), offset: Double(rawOffset) * 0.01, set4mA: Double(raw4) * 0.01, set20mA: Double(raw20) * 0.01, tvg: Int(rawTvg), damp: Int(rawDamp), asf: Int(rawAsf), relayOn: rawRelay == 0)
    }
}
