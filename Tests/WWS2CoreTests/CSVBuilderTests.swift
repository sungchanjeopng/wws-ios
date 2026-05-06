import XCTest
@testable import WWS2Core

final class CSVBuilderTests: XCTestCase {
    func testEscapeWrapsCommaQuoteAndNewline() {
        XCTAssertEqual(CSVBuilder.escape("plain"), "plain")
        XCTAssertEqual(CSVBuilder.escape("A,B"), "\"A,B\"")
        XCTAssertEqual(CSVBuilder.escape("A\"B"), "\"A\"\"B\"")
        XCTAssertEqual(CSVBuilder.escape("A\nB"), "\"A\nB\"")
    }

    func testTrendCSVIncludesHeaderTimestampAndEscapedDeviceId() {
        let record = TrendRecord(
            dateTime: DateComponents(
                calendar: Calendar(identifier: .gregorian),
                year: 2026,
                month: 5,
                day: 4,
                hour: 13,
                minute: 2,
                second: 1
            ),
            eeaD: 123,
            dst: 123.45,
            temperature: 24.5,
            step: 7,
            vca: 9,
            status: 2,
            deviceId: "ENV230,\"A07\""
        )

        let csv = CSVBuilder.makeTrendRecordsCSV([record])
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0], "timestamp,eeaD,dst,dstMeters,temperatureC,step,vca,status,deviceId")
        XCTAssertEqual(lines[1], "2026-05-04 13:02:01,123,123.45,1.23,24.5,7,9,2,\"ENV230,\"\"A07\"\"\"")
    }

    func testDeviceReadingCSVUsesStableUtcTimestamp() {
        let reading = DeviceReading(
            level: 1.23,
            heavyLevel: 0.45,
            temperature: 21.5,
            currentMA: 12.34,
            damping: 5,
            set4mA: 4.0,
            set20mA: 20.0,
            pipeDia: 1,
            freqMHz: 0.380,
            errorCode: 7,
            eeaR: 10,
            eeaD: 20
        )

        let csv = CSVBuilder.makeDeviceReadingCSV(reading, capturedAt: Date(timeIntervalSince1970: 0))
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0], "capturedAt,levelMeters,heavyLevelMeters,temperatureC,currentMA,damping,set4mA,set20mA,pipeDia,pipeDiaLabel,freqMHz,errorCode,eeaR,eeaD")
        XCTAssertEqual(lines[1], "1970-01-01 00:00:00,1.23,0.45,21.5,12.34,5,4.00,20.00,1,200~400mm,0.380,7,10,20")
    }
}
