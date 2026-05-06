import Foundation

/// Incremental notification byte buffer.
/// Current version extracts valid CRC frames by scanning SOF and candidate CRC.
/// Later, optimize with command-specific expected sizes when real notification samples are collected.
public final class FrameAssembler {
    private var buffer: [UInt8] = []
    private let maxFrameSize: Int

    public init(maxFrameSize: Int = 4096) {
        self.maxFrameSize = maxFrameSize
    }

    public func reset() { buffer.removeAll() }

    public func append(_ chunk: [UInt8]) -> [ParsedFrame] {
        buffer.append(contentsOf: chunk)
        if buffer.count > maxFrameSize { buffer.removeFirst(buffer.count - maxFrameSize) }

        var frames: [ParsedFrame] = []
        var progress = true
        while progress {
            progress = false
            while let first = buffer.first, first != FrameCodec.sof { buffer.removeFirst(); progress = true }
            guard buffer.count >= 5 else { break }

            var found: (Int, ParsedFrame)? = nil
            let upper = min(buffer.count, maxFrameSize)
            if upper >= 5 {
                for len in 5...upper {
                    let candidate = Array(buffer[0..<len])
                    if let parsed = FrameCodec.parseFrame(candidate) {
                        found = (len, parsed)
                        break
                    }
                }
            }
            if let (len, parsed) = found {
                frames.append(parsed)
                buffer.removeFirst(len)
                progress = true
            }
        }
        return frames
    }
}
