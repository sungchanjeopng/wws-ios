import Foundation

public struct EchoReading: Equatable {
    public static let intpSize = 816
    public static let mmRange = 300

    public let eeaR: Int
    public let eeaD: Int
    public let level: Double
    public let detAreaLO: Int
    public let detAreaHI: Int
    public let pipeDia: Int
    public let rawWave: [Int]
    public let wave: [Double]
    public let sampleUs: Float
    public let thrLightDist: Int
    public let thrHeavyDist: Int
    public let thrLightAmp: Int
    public let thrHeavyAmp: Int

    public init(eeaR: Int, eeaD: Int, level: Double, detAreaLO: Int, detAreaHI: Int, pipeDia: Int, rawWave: [Int], wave: [Double], sampleUs: Float, thrLightDist: Int, thrHeavyDist: Int, thrLightAmp: Int, thrHeavyAmp: Int) {
        self.eeaR = eeaR; self.eeaD = eeaD; self.level = level; self.detAreaLO = detAreaLO; self.detAreaHI = detAreaHI; self.pipeDia = pipeDia
        self.rawWave = rawWave; self.wave = wave; self.sampleUs = sampleUs; self.thrLightDist = thrLightDist; self.thrHeavyDist = thrHeavyDist; self.thrLightAmp = thrLightAmp; self.thrHeavyAmp = thrHeavyAmp
    }

    public static func fromBytes(_ data: [UInt8], sampleUs: Float = 2.0) -> EchoReading? {
        guard data.count >= 220 else { return nil }
        var r = ByteReader(data)
        guard let eeaR = r.readUInt16BE(), let eeaD = r.readUInt16BE(), let rawLevel = r.readUInt16BE(),
              let detLO = r.readUInt16BE(), let detHI = r.readUInt16BE(), let pipeDia = r.readUInt16BE(),
              let _ = r.readUInt16BE() else { return nil }
        var rawWave: [Int] = []
        for _ in 0..<103 { guard let v = r.readUInt16BE() else { return nil }; rawWave.append(Int(v)) }
        let wave = interpolateX8(rawWave)
        let thrLightDist = data.count >= 222 ? Int((UInt16(data[220]) << 8) | UInt16(data[221])) : 0
        let thrHeavyDist = data.count >= 224 ? Int((UInt16(data[222]) << 8) | UInt16(data[223])) : 0
        let thrLightAmp = data.count >= 226 ? Int((UInt16(data[224]) << 8) | UInt16(data[225])) : 0
        let thrHeavyAmp = data.count >= 228 ? Int((UInt16(data[226]) << 8) | UInt16(data[227])) : 0
        return EchoReading(eeaR: Int(eeaR), eeaD: Int(eeaD), level: Double(rawLevel), detAreaLO: Int(detLO), detAreaHI: Int(detHI), pipeDia: Int(pipeDia), rawWave: rawWave, wave: wave, sampleUs: sampleUs, thrLightDist: thrLightDist, thrHeavyDist: thrHeavyDist, thrLightAmp: thrLightAmp, thrHeavyAmp: thrHeavyAmp)
    }

    private static func interpolateX8(_ src: [Int]) -> [Double] {
        guard src.count >= 103 else { return [] }
        var dst = [Double](repeating: 0, count: intpSize)
        for j in 0..<102 {
            let base = j * 8
            let cur = Double(src[j])
            let nxt = Double(src[j + 1])
            let diff = (nxt - cur) / 8.0
            dst[base] = cur
            for k in 1..<8 where base + k < intpSize { dst[base + k] = cur + diff * Double(k) }
        }
        return dst
    }
}

public struct InterfaceEchoReading: Equatable {
    public let lightLevel: Double
    public let heavyLevel: Double
    public let deadzone: Int
    public let empty: Int
    public let thrLightDist: Int
    public let thrHeavyDist: Int
    public let thrLightReal: Int
    public let thrHeavyReal: Int
    public let thrLightSet: Int
    public let thrHeavySet: Int
    public let thrLightMode: Int
    public let thrHeavyMode: Int
    public let echoAmp: Int
    public let statusCh: Int
    public let temperature: Int
    public let wave: [Int]

    public var statusLabel: String {
        switch statusCh { case 0,4: return "ST00"; case 1: return "ST01"; case 2: return "ST02"; case 3: return "ST03"; case 5: return "ER01"; case 6: return "ER02"; default: return "--" }
    }
    public var thrLightModeLabel: String { thrLightMode == 0 ? "Auto" : "Manual" }
    public var thrHeavyModeLabel: String { thrHeavyMode == 0 ? "Auto" : "Manual" }

    public func toEchoReading() -> EchoReading {
        EchoReading(eeaR: echoAmp, eeaD: echoAmp, level: lightLevel, detAreaLO: deadzone, detAreaHI: empty, pipeDia: 0, rawWave: wave, wave: wave.map(Double.init), sampleUs: 2.0, thrLightDist: thrLightDist, thrHeavyDist: thrHeavyDist, thrLightAmp: thrLightReal, thrHeavyAmp: thrHeavyReal)
    }

    public static func fromBytes(_ data: [UInt8]) -> InterfaceEchoReading? {
        guard data.count >= 30 else { return nil }
        var r = ByteReader(data)
        guard let rawLight = r.readUInt16BE(), let rawHeavy = r.readUInt16BE(), let deadzone = r.readUInt16BE(), let empty = r.readUInt16BE(),
              let thrLightDist = r.readUInt16BE(), let thrHeavyDist = r.readUInt16BE(), let thrLightReal = r.readUInt16BE(), let thrHeavyReal = r.readUInt16BE(),
              let thrLightSet = r.readUInt16BE(), let thrHeavySet = r.readUInt16BE(), let thrLightMode = r.readUInt16BE(), let thrHeavyMode = r.readUInt16BE(),
              let echoAmp = r.readUInt16BE(), let statusCh = r.readUInt16BE(), let temperature = r.readInt16BE() else { return nil }
        var wave: [Int] = []
        while r.remaining >= 2 { guard let v = r.readUInt16BE() else { break }; wave.append(Int(v)) }
        return InterfaceEchoReading(lightLevel: Double(rawLight) * 0.01, heavyLevel: Double(rawHeavy) * 0.01, deadzone: Int(deadzone), empty: Int(empty), thrLightDist: Int(thrLightDist), thrHeavyDist: Int(thrHeavyDist), thrLightReal: Int(thrLightReal), thrHeavyReal: Int(thrHeavyReal), thrLightSet: Int(thrLightSet), thrHeavySet: Int(thrHeavySet), thrLightMode: Int(thrLightMode), thrHeavyMode: Int(thrHeavyMode), echoAmp: Int(echoAmp), statusCh: Int(statusCh), temperature: Int(temperature), wave: wave)
    }
}
