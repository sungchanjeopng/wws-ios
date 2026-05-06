import Foundation

public enum DeviceType: String, Codable, Equatable {
    case density = "ENV230"
    case interface = "ENV130"
    case unknown
}

public struct DeviceReading: Equatable {
    public let level: Double
    public let temperature: Double
    public let currentMA: Double
    public let damping: Int
    public let set4mA: Double
    public let set20mA: Double
    public let pipeDia: Int
    public let freqMHz: Double
    public let eeaR: Int
    public let eeaD: Int
    public let heavyLevel: Double?
    public let errorCode: Int

    public init(level: Double, temperature: Double, currentMA: Double, damping: Int, set4mA: Double, set20mA: Double, pipeDia: Int, freqMHz: Double, eeaR: Int = 0, eeaD: Int = 0, heavyLevel: Double? = nil, errorCode: Int = 0) {
        self.level = level; self.temperature = temperature; self.currentMA = currentMA; self.damping = damping
        self.set4mA = set4mA; self.set20mA = set20mA; self.pipeDia = pipeDia; self.freqMHz = freqMHz
        self.eeaR = eeaR; self.eeaD = eeaD; self.heavyLevel = heavyLevel; self.errorCode = errorCode
    }

    public var pipeDiaLabel: String {
        switch pipeDia { case 0: return "0~200mm"; case 1: return "200~400mm"; case 2: return "400~600mm"; default: return "--" }
    }

    public static func fromBytes(_ data: [UInt8]) -> DeviceReading? {
        guard data.count == 16 else { return nil }
        var r = ByteReader(data)
        guard let rawLevel = r.readUInt16BE(), let rawTemp = r.readInt16BE(), let rawCurrent = r.readUInt16BE(),
              let rawDamping = r.readUInt16BE(), let raw4 = r.readUInt16BE(), let raw20 = r.readUInt16BE(),
              let rawPipe = r.readUInt16BE(), let rawFreq = r.readUInt16BE() else { return nil }
        return DeviceReading(level: Double(rawLevel), temperature: Double(rawTemp) * 0.1, currentMA: Double(rawCurrent) * 0.01, damping: Int(rawDamping), set4mA: Double(raw4) * 0.01, set20mA: Double(raw20) * 0.01, pipeDia: Int(rawPipe), freqMHz: Double(rawFreq) * 0.001)
    }
}

public struct ScannedDevice: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let rawName: String
    public let rssi: Int
    public let type: DeviceType

    public init(id: UUID, name: String, rawName: String, rssi: Int, type: DeviceType) {
        self.id = id; self.name = name; self.rawName = rawName; self.rssi = rssi; self.type = type
    }

    public var signalLevel: Int { rssi >= -55 ? 3 : (rssi >= -72 ? 2 : 1) }
}

public struct ConnectedDevice: Identifiable, Equatable {
    public let id: UUID
    public var label: String
    public var name: String
    public var type: DeviceType
    public var reading: DeviceReading?

    public init(id: UUID, label: String, name: String, type: DeviceType, reading: DeviceReading? = nil) {
        self.id = id; self.label = label; self.name = name; self.type = type; self.reading = reading
    }
}
