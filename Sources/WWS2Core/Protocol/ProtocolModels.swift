import Foundation

public struct FwVersion: Equatable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major; self.minor = minor; self.patch = patch
    }
    public var description: String { "v\(major).\(minor).\(patch)" }
}

public struct DeviceInfo: Equatable {
    public let siteNameHi: Character
    public let siteNameLo: Int
    public let ch2SiteNameHi: Character
    public let ch2SiteNameLo: Int
    public let fwVersion: FwVersion

    public init(siteNameHi: Character, siteNameLo: Int, ch2SiteNameHi: Character = "\0", ch2SiteNameLo: Int = 0, fwVersion: FwVersion) {
        self.siteNameHi = siteNameHi; self.siteNameLo = siteNameLo
        self.ch2SiteNameHi = ch2SiteNameHi; self.ch2SiteNameLo = ch2SiteNameLo
        self.fwVersion = fwVersion
    }
}

public enum PairingResult: Equatable {
    case success(DeviceInfo)
    case pinFailed
}

public struct ParsedFrame: Equatable {
    public let cmd: Int
    public let data: [UInt8]
    public init(cmd: Int, data: [UInt8]) { self.cmd = cmd; self.data = data }
}
