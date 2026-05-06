import XCTest
@testable import WWS2Core

final class ModelParserTests: XCTestCase {
    func testTrendRecordFromBytes() {
        let bytes: [UInt8] =
            [0x00, 0x18, 0x00, 0x05, 0x00, 0x04, 0x00, 0x0D, 0x00, 0x2A, 0x00, 0x3B] +
            u16(300) + u16(1000) + i16(-100) + u16(2) + u16(500) + u16(3)

        guard let record = TrendRecord.fromBytes(bytes) else {
            return XCTFail("expected trend record")
        }

        XCTAssertEqual(record.dateTime.year, 2024)
        XCTAssertEqual(record.dateTime.month, 5)
        XCTAssertEqual(record.dateTime.day, 4)
        XCTAssertEqual(record.dateTime.hour, 13)
        XCTAssertEqual(record.dateTime.minute, 42)
        XCTAssertEqual(record.dateTime.second, 59)
        XCTAssertEqual(record.eeaD, 300)
        XCTAssertEqual(record.dst, 1000.0, accuracy: 0.0001)
        XCTAssertEqual(record.dstMeters, 10.0, accuracy: 0.0001)
        XCTAssertEqual(record.temperature, -10.0, accuracy: 0.0001)
        XCTAssertEqual(record.step, 2)
        XCTAssertEqual(record.vca, 500)
        XCTAssertEqual(record.status, 3)
        XCTAssertNotNil(record.date)
    }

    func testDiagReadingFromBytes() {
        let bytes = i16(251) + u16(1234) + u16(5) + u16(100) + u16(2000) + u16(2) + u16(370) + u16(9)
        guard let diag = DiagReading.fromBytes(bytes) else {
            return XCTFail("expected diag reading")
        }

        XCTAssertEqual(diag.temperature, 25.1, accuracy: 0.0001)
        XCTAssertEqual(diag.currentMA, 12.34, accuracy: 0.0001)
        XCTAssertEqual(diag.damping, 5)
        XCTAssertEqual(diag.set4mA, 1.0, accuracy: 0.0001)
        XCTAssertEqual(diag.set20mA, 20.0, accuracy: 0.0001)
        XCTAssertEqual(diag.pipeDia, 2)
        XCTAssertEqual(diag.freqMHz, 0.370, accuracy: 0.0001)
        XCTAssertEqual(diag.errorCode, 9)
    }

    func testInterfaceDiagReadingFromBytes() {
        let bytes = i16(250) + u16(1234) + u16(3) + i16(-15) + u16(100) + u16(2000) + u16(12) + u16(7) + u16(9) + u16(0) + u16(4)
        guard let diag = InterfaceDiagReading.fromBytes(bytes) else {
            return XCTFail("expected interface diag reading")
        }

        XCTAssertEqual(diag.temperature, 25.0, accuracy: 0.0001)
        XCTAssertEqual(diag.currentMA, 12.34, accuracy: 0.0001)
        XCTAssertEqual(diag.freq, 3)
        XCTAssertEqual(diag.freqLabel, "380K")
        XCTAssertEqual(diag.offset, -0.15, accuracy: 0.0001)
        XCTAssertEqual(diag.set4mA, 1.0, accuracy: 0.0001)
        XCTAssertEqual(diag.set20mA, 20.0, accuracy: 0.0001)
        XCTAssertEqual(diag.tvg, 12)
        XCTAssertEqual(diag.damp, 7)
        XCTAssertEqual(diag.asf, 9)
        XCTAssertEqual(diag.relayOn, true)
        XCTAssertEqual(diag.errorCode, 4)
    }

    func testEchoReadingFromBytesInterpolatesWave() {
        let rawWave = Array(0...102).flatMap { u16($0) }
        let bytes = u16(10) + u16(20) + u16(1000) + u16(5) + u16(10) + u16(2) + u16(0) +
            rawWave + u16(142) + u16(165) + u16(2000) + u16(2200)

        guard let echo = EchoReading.fromBytes(bytes, sampleUs: 3.2) else {
            return XCTFail("expected echo reading")
        }

        XCTAssertEqual(echo.eeaR, 10)
        XCTAssertEqual(echo.eeaD, 20)
        XCTAssertEqual(echo.level, 1000.0, accuracy: 0.0001)
        XCTAssertEqual(echo.thrLightDist, 142)
        XCTAssertEqual(echo.thrHeavyDist, 165)
        XCTAssertEqual(echo.thrLightAmp, 2000)
        XCTAssertEqual(echo.thrHeavyAmp, 2200)
        XCTAssertEqual(echo.rawWave.count, 103)
        XCTAssertEqual(echo.wave.count, EchoReading.interpolatedWaveSampleCount)
        XCTAssertEqual(echo.wave[0], 0.0, accuracy: 0.0001)
        XCTAssertEqual(echo.wave[8], 1.0, accuracy: 0.0001)
        XCTAssertEqual(echo.sampleUs, 3.2, accuracy: 0.0001)
    }

    private func u16(_ value: Int) -> [UInt8] {
        [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    private func i16(_ value: Int) -> [UInt8] {
        let raw = UInt16(bitPattern: Int16(value))
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }
}
