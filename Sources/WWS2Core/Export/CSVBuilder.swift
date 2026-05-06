import Foundation

public enum CSVBuilder {
    public static func build(headers: [String], rows: [[String]]) -> String {
        guard !headers.isEmpty else { return "" }

        var lines: [String] = [serializeRow(headers)]
        lines.append(contentsOf: rows.map(serializeRow))
        return lines.joined(separator: "\n")
    }

    public static func makeTrendRecordsCSV(_ records: [TrendRecord]) -> String {
        guard !records.isEmpty else { return "" }

        let rows = records.map { record in
            [
                record.timestampLabel,
                String(record.eeaD),
                decimal(record.dst, places: 2),
                decimal(record.dstMeters, places: 2),
                decimal(record.temperature, places: 1),
                String(record.step),
                String(record.vca),
                String(record.status),
                record.deviceId,
            ]
        }

        return build(
            headers: [
                "timestamp",
                "eeaD",
                "dst",
                "dstMeters",
                "temperatureC",
                "step",
                "vca",
                "status",
                "deviceId",
            ],
            rows: rows
        )
    }

    public static func makeDeviceReadingCSV(_ reading: DeviceReading, capturedAt: Date = Date()) -> String {
        build(
            headers: [
                "capturedAt",
                "levelMeters",
                "heavyLevelMeters",
                "temperatureC",
                "currentMA",
                "damping",
                "set4mA",
                "set20mA",
                "pipeDia",
                "pipeDiaLabel",
                "freqMHz",
                "errorCode",
                "eeaR",
                "eeaD",
            ],
            rows: [[
                timestampString(from: capturedAt),
                decimal(reading.level, places: 2),
                decimal(reading.heavyLevel, places: 2),
                decimal(reading.temperature, places: 1),
                decimal(reading.currentMA, places: 2),
                String(reading.damping),
                decimal(reading.set4mA, places: 2),
                decimal(reading.set20mA, places: 2),
                String(reading.pipeDia),
                reading.pipeDiaLabel,
                decimal(reading.freqMHz, places: 3),
                String(reading.errorCode),
                String(reading.eeaR),
                String(reading.eeaD),
            ]]
        )
    }

    public static func escape(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        guard needsQuotes else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    public static func timestampString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func serializeRow(_ values: [String]) -> String {
        values.map(escape).joined(separator: ",")
    }

    private static func decimal(_ value: Double, places: Int) -> String {
        String(format: "%.\(places)f", value)
    }
}
