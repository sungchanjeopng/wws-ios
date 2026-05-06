import Foundation
import WWS2Core

/// OTA placeholder. Implement after scan/connect/notify/write stability is verified on a real iPhone
/// with a physical WESSWARE device. iOS cannot request Android-style MTU 247 and cannot force PHY 2M,
/// so chunk sizing must be derived from `maximumWriteValueLength(for:)`.
public final class OtaUploadManager {
    public init() {}

    public func chunkSize(maximumWriteLength: Int) -> Int {
        min(200, max(20, maximumWriteLength))
    }

    public func crc32(_ firmware: [UInt8]) -> UInt32 {
        Crc.crc32(firmware)
    }
}
