import Foundation

public struct ScannedDevice: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let rawName: String
    public let rssi: Int
    public let ch1SiteName: String
    public let ch2SiteName: String

    public init(
        id: String,
        name: String,
        rawName: String,
        rssi: Int,
        ch1SiteName: String = "",
        ch2SiteName: String = ""
    ) {
        self.id = id
        self.name = name
        self.rawName = rawName
        self.rssi = rssi
        self.ch1SiteName = ch1SiteName
        self.ch2SiteName = ch2SiteName
    }
}

public struct ConnectedBleDevice: Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let type: DeviceType

    public init(id: String, label: String, type: DeviceType) {
        self.id = id
        self.label = label
        self.type = type
    }
}

public struct DeviceReading: Equatable, Sendable {
    public var level: Double
    public var heavyLevel: Double
    public var temperature: Double
    public var currentMA: Double
    public var damping: Int
    public var set4mA: Double
    public var set20mA: Double
    public var pipeDia: Int
    public var freqMHz: Double
    public var errorCode: Int
    public var eeaR: Int
    public var eeaD: Int

    public init(
        level: Double = 0,
        heavyLevel: Double = 0,
        temperature: Double = 0,
        currentMA: Double = 0,
        damping: Int = 0,
        set4mA: Double = 0,
        set20mA: Double = 0,
        pipeDia: Int = 0,
        freqMHz: Double = 0,
        errorCode: Int = 0,
        eeaR: Int = 0,
        eeaD: Int = 0
    ) {
        self.level = level
        self.heavyLevel = heavyLevel
        self.temperature = temperature
        self.currentMA = currentMA
        self.damping = damping
        self.set4mA = set4mA
        self.set20mA = set20mA
        self.pipeDia = pipeDia
        self.freqMHz = freqMHz
        self.errorCode = errorCode
        self.eeaR = eeaR
        self.eeaD = eeaD
    }

    public var pipeDiaLabel: String {
        switch pipeDia {
        case 0: return "0~200mm"
        case 1: return "200~400mm"
        case 2: return "400~600mm"
        default: return "--"
        }
    }
}

public struct TrendRecord: Equatable, Sendable {
    public let dateTime: DateComponents
    public let eeaD: Int
    public let dst: Double
    public let temperature: Double
    public let step: Int
    public let vca: Int
    public let status: Int
    public let deviceId: String

    public init(
        dateTime: DateComponents = Self.currentDateTime(),
        eeaD: Int,
        dst: Double,
        temperature: Double,
        step: Int = 0,
        vca: Int = 0,
        status: Int = 0,
        deviceId: String = ""
    ) {
        self.dateTime = dateTime
        self.eeaD = eeaD
        self.dst = dst
        self.temperature = temperature
        self.step = step
        self.vca = vca
        self.status = status
        self.deviceId = deviceId
    }

    public var date: Date? {
        var components = dateTime
        components.calendar = Calendar(identifier: .gregorian)
        return components.calendar?.date(from: components)
    }

    public var dstMeters: Double {
        dst * 0.01
    }

    public var timestampLabel: String {
        let year = dateTime.year ?? 0
        let month = dateTime.month ?? 0
        let day = dateTime.day ?? 0
        let hour = dateTime.hour ?? 0
        let minute = dateTime.minute ?? 0
        let second = dateTime.second ?? 0

        return String(
            format: "%04d-%02d-%02d %02d:%02d:%02d",
            year,
            month,
            day,
            hour,
            minute,
            second
        )
    }

    public static func fromBytes(_ data: [UInt8]) -> TrendRecord? {
        guard data.count >= 24 else { return nil }

        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2000 + Int(data[1]),
            month: Int(data[3]).clamped(to: 1...12),
            day: Int(data[5]).clamped(to: 1...31),
            hour: Int(data[7]).clamped(to: 0...23),
            minute: Int(data[9]).clamped(to: 0...59),
            second: Int(data[11]).clamped(to: 0...59)
        )

        var reader = ByteReader(Array(data[12..<24]))
        guard
            let eeaD = reader.readUInt16BE(),
            let rawDst = reader.readUInt16BE(),
            let rawTemp = reader.readInt16BE(),
            let step = reader.readUInt16BE(),
            let vca = reader.readUInt16BE(),
            let status = reader.readUInt16BE()
        else {
            return nil
        }

        return TrendRecord(
            dateTime: components,
            eeaD: Int(eeaD),
            dst: Double(rawDst),
            temperature: Double(rawTemp) * 0.1,
            step: Int(step),
            vca: Int(vca),
            status: Int(status)
        )
    }

    private static func currentDateTime() -> DateComponents {
        Calendar(identifier: .gregorian).dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: Date()
        )
    }
}

public struct EchoReading: Equatable, Sendable {
    public static let rawWaveSampleCount = 103
    public static let interpolatedWaveSampleCount = 816

    public let eeaR: Int
    public let eeaD: Int
    public let level: Double
    public let detAreaLO: Int
    public let detAreaHI: Int
    public let pipeDia: Int
    public let rawWave: [Int]
    public let wave: [Double]
    public let sampleUs: Double
    public let thrLightDist: Int
    public let thrHeavyDist: Int
    public let thrLightAmp: Int
    public let thrHeavyAmp: Int

    public init(
        eeaR: Int,
        eeaD: Int,
        level: Double,
        detAreaLO: Int,
        detAreaHI: Int,
        pipeDia: Int,
        rawWave: [Int],
        wave: [Double],
        sampleUs: Double,
        thrLightDist: Int,
        thrHeavyDist: Int,
        thrLightAmp: Int,
        thrHeavyAmp: Int
    ) {
        self.eeaR = eeaR
        self.eeaD = eeaD
        self.level = level
        self.detAreaLO = detAreaLO
        self.detAreaHI = detAreaHI
        self.pipeDia = pipeDia
        self.rawWave = rawWave
        self.wave = wave
        self.sampleUs = sampleUs
        self.thrLightDist = thrLightDist
        self.thrHeavyDist = thrHeavyDist
        self.thrLightAmp = thrLightAmp
        self.thrHeavyAmp = thrHeavyAmp
    }

    public var levelMeters: Double {
        level * 0.01
    }

    public static func fromBytes(_ data: [UInt8], sampleUs: Double = 2.0) -> EchoReading? {
        guard data.count >= 220 else { return nil }

        var reader = ByteReader(data)
        guard
            let eeaR = reader.readUInt16BE(),
            let eeaD = reader.readUInt16BE(),
            let rawLevel = reader.readUInt16BE(),
            let detAreaLO = reader.readUInt16BE(),
            let detAreaHI = reader.readUInt16BE(),
            let pipeDia = reader.readUInt16BE()
        else {
            return nil
        }

        guard reader.skip(2) else { return nil }

        var rawWave: [Int] = []
        rawWave.reserveCapacity(rawWaveSampleCount)
        for _ in 0..<rawWaveSampleCount {
            guard let sample = reader.readUInt16BE() else { return nil }
            rawWave.append(Int(sample))
        }

        let thrLightDist = reader.readUInt16BE().map(Int.init) ?? 0
        let thrHeavyDist = reader.readUInt16BE().map(Int.init) ?? 0
        let thrLightAmp = reader.readUInt16BE().map(Int.init) ?? 0
        let thrHeavyAmp = reader.readUInt16BE().map(Int.init) ?? 0

        return EchoReading(
            eeaR: Int(eeaR),
            eeaD: Int(eeaD),
            level: Double(rawLevel),
            detAreaLO: Int(detAreaLO),
            detAreaHI: Int(detAreaHI),
            pipeDia: Int(pipeDia),
            rawWave: rawWave,
            wave: interpolateX8(rawWave),
            sampleUs: sampleUs,
            thrLightDist: thrLightDist,
            thrHeavyDist: thrHeavyDist,
            thrLightAmp: thrLightAmp,
            thrHeavyAmp: thrHeavyAmp
        )
    }

    private static func interpolateX8(_ source: [Int]) -> [Double] {
        guard source.count >= rawWaveSampleCount else { return source.map(Double.init) }

        var destination = Array(repeating: 0.0, count: interpolatedWaveSampleCount)
        for index in 0..<102 {
            let base = index * 8
            let current = Double(source[index])
            let next = Double(source[index + 1])
            let diff = (next - current) / 8.0
            destination[base] = current
            for step in 1..<8 {
                let target = base + step
                guard target < interpolatedWaveSampleCount else { break }
                destination[target] = current + (diff * Double(step))
            }
        }
        return destination
    }
}

public struct DiagReading: Equatable, Sendable {
    public let temperature: Double
    public let currentMA: Double
    public let damping: Int
    public let set4mA: Double
    public let set20mA: Double
    public let pipeDia: Int
    public let freqMHz: Double
    public let errorCode: Int

    public init(
        temperature: Double,
        currentMA: Double,
        damping: Int,
        set4mA: Double,
        set20mA: Double,
        pipeDia: Int,
        freqMHz: Double,
        errorCode: Int = 0
    ) {
        self.temperature = temperature
        self.currentMA = currentMA
        self.damping = damping
        self.set4mA = set4mA
        self.set20mA = set20mA
        self.pipeDia = pipeDia
        self.freqMHz = freqMHz
        self.errorCode = errorCode
    }

    public static func fromBytes(_ data: [UInt8]) -> DiagReading? {
        guard data.count == 16 else { return nil }

        var reader = ByteReader(data)
        guard
            let rawTemp = reader.readInt16BE(),
            let rawCurrent = reader.readUInt16BE(),
            let damping = reader.readUInt16BE(),
            let set4mA = reader.readUInt16BE(),
            let set20mA = reader.readUInt16BE(),
            let pipeDia = reader.readUInt16BE(),
            let rawFreq = reader.readUInt16BE(),
            let errorCode = reader.readUInt16BE()
        else {
            return nil
        }

        return DiagReading(
            temperature: Double(rawTemp) * 0.1,
            currentMA: Double(rawCurrent) * 0.01,
            damping: Int(damping),
            set4mA: Double(set4mA) * 0.01,
            set20mA: Double(set20mA) * 0.01,
            pipeDia: Int(pipeDia),
            freqMHz: Double(rawFreq) * 0.001,
            errorCode: Int(errorCode)
        )
    }
}

public struct InterfaceDiagReading: Equatable, Sendable {
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
    public let errorCode: Int

    public init(
        temperature: Double,
        currentMA: Double,
        freq: Int,
        offset: Double,
        set4mA: Double,
        set20mA: Double,
        tvg: Int,
        damp: Int,
        asf: Int,
        relayOn: Bool,
        errorCode: Int = 0
    ) {
        self.temperature = temperature
        self.currentMA = currentMA
        self.freq = freq
        self.offset = offset
        self.set4mA = set4mA
        self.set20mA = set20mA
        self.tvg = tvg
        self.damp = damp
        self.asf = asf
        self.relayOn = relayOn
        self.errorCode = errorCode
    }

    public var freqLabel: String {
        switch freq {
        case 0: return "130K"
        case 1: return "160K"
        case 2: return "270K"
        case 3: return "380K"
        default: return "--"
        }
    }

    public static func fromBytes(_ data: [UInt8]) -> InterfaceDiagReading? {
        guard data.count >= 22 else { return nil }

        var reader = ByteReader(data)
        guard
            let rawTemp = reader.readInt16BE(),
            let rawCurrent = reader.readUInt16BE(),
            let rawFreq = reader.readUInt16BE(),
            let rawOffset = reader.readInt16BE(),
            let raw4mA = reader.readUInt16BE(),
            let raw20mA = reader.readUInt16BE(),
            let rawTvg = reader.readUInt16BE(),
            let rawDamp = reader.readUInt16BE(),
            let rawAsf = reader.readUInt16BE(),
            let rawRelay = reader.readUInt16BE(),
            let rawError = reader.readUInt16BE()
        else {
            return nil
        }

        return InterfaceDiagReading(
            temperature: Double(rawTemp) * 0.1,
            currentMA: Double(rawCurrent) * 0.01,
            freq: Int(rawFreq),
            offset: Double(rawOffset) * 0.01,
            set4mA: Double(raw4mA) * 0.01,
            set20mA: Double(raw20mA) * 0.01,
            tvg: Int(rawTvg),
            damp: Int(rawDamp),
            asf: Int(rawAsf),
            relayOn: rawRelay == 0,
            errorCode: Int(rawError)
        )
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
