import XCTest
@testable import WWS2Core

final class TrendStreamParserTests: XCTestCase {
    func testParsesHeaderRecordAndFinalCRC() {
        let parser = TrendStreamParser()
        parser.startStream()

        let header = makeTrendHeader(totalRecords: 1, cmd: Command.trend)
        let record: [UInt8] =
            [0x00, 0x18, 0x00, 0x05, 0x00, 0x04, 0x00, 0x0D, 0x00, 0x2A, 0x00, 0x3B] +
            u16(300) + u16(1000) + i16(-100) + u16(2) + u16(500) + u16(3)
        let crc = Crc.crc16Modbus(record)
        let body = record + [UInt8(crc & 0xFF), UInt8((crc >> 8) & 0xFF)]

        let headerEvents = parser.append(header, downloadedCount: 0)
        XCTAssertEqual(headerEvents, [.header(totalRecords: 1)])

        let bodyEvents = parser.append(body, downloadedCount: 0)
        XCTAssertEqual(bodyEvents.count, 2)
        guard case let .records(records) = bodyEvents[0] else {
            return XCTFail("expected records event")
        }
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.eeaD, 300)
        XCTAssertEqual(bodyEvents[1], .completed)
        XCTAssertFalse(parser.isActive)
    }

    func testHeaderCrcFailure() {
        let parser = TrendStreamParser()
        parser.startStream()

        var header = makeTrendHeader(totalRecords: 1, cmd: Command.trend)
        header[5] ^= 0xFF

        let events = parser.append(header, downloadedCount: 0)
        XCTAssertEqual(events, [.crcFailure(reason: "header CRC FAIL")])
        XCTAssertFalse(parser.isActive)
    }

    private func makeTrendHeader(totalRecords: Int, cmd: Int) -> [UInt8] {
        var header: [UInt8] = [
            FrameCodec.sof,
            UInt8((cmd >> 8) & 0xFF),
            UInt8(cmd & 0xFF),
            UInt8((totalRecords >> 8) & 0xFF),
            UInt8(totalRecords & 0xFF),
        ]
        let crc = Crc.crc16Modbus(header)
        header.append(UInt8(crc & 0xFF))
        header.append(UInt8((crc >> 8) & 0xFF))
        return header
    }

    private func u16(_ value: Int) -> [UInt8] {
        [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    private func i16(_ value: Int) -> [UInt8] {
        let raw = UInt16(bitPattern: Int16(value))
        return [UInt8((raw >> 8) & 0xFF), UInt8(raw & 0xFF)]
    }
}
