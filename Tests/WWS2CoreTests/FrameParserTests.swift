import XCTest
@testable import WWS2Core

final class FrameParserTests: XCTestCase {
    func testStatus4B() {
        let result = FrameParser.parse(cmd: Command.status, data: [0x03, 0xE8, 0x00, 0x02], isInterface: false)

        guard case let .status4B(reading)? = result else {
            return XCTFail("expected status4B")
        }

        XCTAssertEqual(reading.level, 10.0, accuracy: 0.0001)
        XCTAssertEqual(reading.errorCode, 2)
    }

    func testDensityStatus34B() {
        let data = u16(1000) + u16(20) + u16(30) + i16(-100) + u16(1234) + u16(3) + u16(100) +
            u16(2000) + u16(2) + u16(370) + u16(9) + u16(1) + u16(4) + u16(1) + u16(0) + u16(1) + u16(1)

        let result = FrameParser.parse(cmd: Command.status, data: data, isInterface: false)

        guard case let .densityStatus(reading, trendRecord, relay, densUnit, extIn1En, extIn1State, extIn2En, extIn2State)? = result else {
            return XCTFail("expected densityStatus")
        }

        XCTAssertEqual(reading.level, 10.0, accuracy: 0.0001)
        XCTAssertEqual(reading.eeaD, 20)
        XCTAssertEqual(reading.eeaR, 30)
        XCTAssertEqual(reading.temperature, -10.0, accuracy: 0.0001)
        XCTAssertEqual(reading.currentMA, 12.34, accuracy: 0.0001)
        XCTAssertEqual(reading.freqMHz, 0.370, accuracy: 0.0001)
        XCTAssertEqual(relay, 1)
        XCTAssertEqual(densUnit, 4)
        XCTAssertEqual(extIn1En, 1)
        XCTAssertEqual(extIn1State, 0)
        XCTAssertEqual(extIn2En, 1)
        XCTAssertEqual(extIn2State, 1)
        XCTAssertEqual(trendRecord.dst, 10.0, accuracy: 0.0001)
    }

    func testInterfaceStatus26B() {
        let data = u16(321) + u16(654) + i16(250) + u16(1500) + u16(2) + i16(-25) +
            u16(100) + u16(2000) + u16(8) + u16(5) + u16(3) + u16(1) + u16(2)

        let result = FrameParser.parse(cmd: Command.statusCH2, data: data, isInterface: true)

        guard case let .interfaceStatus(reading, temperature, currentMA, damping, set4mA, set20mA, freqMHz, tvg, offset, asf, relay, trendRecord)? = result else {
            return XCTFail("expected interfaceStatus")
        }

        XCTAssertEqual(reading.level, 3.21, accuracy: 0.0001)
        XCTAssertEqual(reading.heavyLevel, 6.54, accuracy: 0.0001)
        XCTAssertEqual(temperature, 25.0, accuracy: 0.0001)
        XCTAssertEqual(currentMA, 15.0, accuracy: 0.0001)
        XCTAssertEqual(damping, 5)
        XCTAssertEqual(set4mA, 1.0, accuracy: 0.0001)
        XCTAssertEqual(set20mA, 20.0, accuracy: 0.0001)
        XCTAssertEqual(freqMHz, 0.160, accuracy: 0.0001)
        XCTAssertEqual(tvg, 8)
        XCTAssertEqual(offset, -0.25, accuracy: 0.0001)
        XCTAssertEqual(asf, 3)
        XCTAssertEqual(relay, 1)
        XCTAssertEqual(trendRecord.eeaD, 654)
    }

    func testDensityEchoWithOptionalSampleUs() {
        let rawWave = Array(0...102).flatMap { u16($0) }
        let echoHeader = u16(10) + u16(20) + u16(1000) + u16(5) + u16(10) + u16(2) + u16(0)
        let data = echoHeader + i16(-100) + rawWave + u16(4) + u16(320)

        let result = FrameParser.parse(cmd: Command.echo, data: data, isInterface: false)

        guard case let .densityEcho(echo, temperature, trendRecord, densUnit)? = result else {
            return XCTFail("expected densityEcho")
        }

        XCTAssertEqual(echo.eeaR, 10)
        XCTAssertEqual(echo.eeaD, 20)
        XCTAssertEqual(echo.level, 1000.0, accuracy: 0.0001)
        XCTAssertEqual(echo.detAreaLO, 5)
        XCTAssertEqual(echo.detAreaHI, 10)
        XCTAssertEqual(echo.rawWave.count, 103)
        XCTAssertEqual(echo.wave.count, EchoReading.interpolatedWaveSampleCount)
        XCTAssertEqual(echo.sampleUs, 3.2, accuracy: 0.0001)
        XCTAssertEqual(temperature, -10.0, accuracy: 0.0001)
        XCTAssertEqual(trendRecord.dst, 1000.0, accuracy: 0.0001)
        XCTAssertEqual(densUnit, 4)
    }

    private func u16(_ value: Int) -> [UInt8] {
        [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    private func i16(_ value: Int) -> [UInt8] {
        let raw = UInt16(bitPattern: Int16(value))
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }
}
