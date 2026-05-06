import Foundation

public enum FrameCodec {
    public static let sof: UInt8 = 0x02

    public static func buildDeviceInfoRequest(pin: Int = 0) -> [UInt8] {
        let payload: [UInt8] = [
            sof,
            0x00,
            UInt8(Command.deviceInfo & 0xFF),
            UInt8((pin >> 8) & 0xFF),
            UInt8(pin & 0xFF),
        ]
        return appendCrc(payload)
    }

    public static func parsePairingResponse(_ frame: [UInt8]) -> PairingResult? {
        guard frame.count >= 7, frame[0] == sof else { return nil }
        let cmd = (Int(frame[1]) << 8) | Int(frame[2])
        guard cmd == Command.deviceInfo else { return nil }
        let crcExpected = Crc.crc16Modbus(Array(frame[0..<5]))
        let crcReceived = UInt16(frame[5]) | (UInt16(frame[6]) << 8)
        guard crcExpected == crcReceived else { return nil }
        let result = (Int(frame[3]) << 8) | Int(frame[4])
        if result == 0x0000 {
            return .success(DeviceInfo(siteNameHi: "?", siteNameLo: 0, fwVersion: FwVersion(0, 0, 0)))
        }
        return .pinFailed
    }

    public static func buildFrame(command lenOrCommand: Int, data: [UInt8] = []) -> [UInt8] {
        let payload: [UInt8] = [sof, UInt8((lenOrCommand >> 8) & 0xFF), UInt8(lenOrCommand & 0xFF)] + data
        return appendCrc(payload)
    }

    public static func buildHeartbeat(pageIndex: Int, expectedLen: Int = 0) -> [UInt8] {
        let payload: [UInt8] = [
            sof,
            UInt8((pageIndex >> 8) & 0xFF), UInt8(pageIndex & 0xFF),
            UInt8((expectedLen >> 8) & 0xFF), UInt8(expectedLen & 0xFF),
        ]
        return appendCrc(payload)
    }

    public static func parseFrame(_ raw: [UInt8]) -> ParsedFrame? {
        guard raw.count >= 5, raw[0] == sof else { return nil }
        let payloadEnd = raw.count - 2
        let crcReceived = UInt16(raw[payloadEnd]) | (UInt16(raw[payloadEnd + 1]) << 8)
        let crcCalc = Crc.crc16Modbus(Array(raw[0..<payloadEnd]))
        guard crcReceived == crcCalc else { return nil }
        let cmd = (Int(raw[1]) << 8) | Int(raw[2])
        let data = payloadEnd > 3 ? Array(raw[3..<payloadEnd]) : []
        return ParsedFrame(cmd: cmd, data: data)
    }

    public static func makeStartFrame() -> [UInt8] { buildHeartbeat(pageIndex: Command.otaStart) }
    public static func makeEndFrame() -> [UInt8] { buildHeartbeat(pageIndex: Command.otaEnd) }

    public static func u32le(_ v: UInt32) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)]
    }

    public static func indexOfSubsequence(data: [UInt8], pattern: [UInt8]) -> Int? {
        guard !pattern.isEmpty, data.count >= pattern.count else { return nil }
        for i in 0...(data.count - pattern.count) {
            if Array(data[i..<(i + pattern.count)]) == pattern { return i }
        }
        return nil
    }

    private static func appendCrc(_ payload: [UInt8]) -> [UInt8] {
        let crc = Crc.crc16Modbus(payload)
        return payload + [UInt8(crc & 0xFF), UInt8((crc >> 8) & 0xFF)]
    }
}
