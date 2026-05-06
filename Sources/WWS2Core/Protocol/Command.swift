import Foundation

public enum Command {
    public static let deviceInfo = 0x00F0
    public static let otaStart = 0x0050
    public static let otaEnd = 0x0051

    public static let status = 0x0000
    public static let echo = 0x0001
    public static let trend = 0x0002
    public static let calib = 0x0003
    public static let diag = 0x0004

    public static let interfaceEchoReal = 0x0001
    public static let interfaceEchoAvg = 0x0005

    public static let statusCH2 = 0x0010
    public static let echoCH2 = 0x0011
    public static let trendCH2 = 0x0012
    public static let diagCH2 = 0x0014
    public static let interfaceEchoAvgCH2 = 0x0015

    public static let download = 0x0007
    public static let downloadCH2 = 0x0017
    public static let downloadCancel = 0x0008
    public static let downloadCancelCH2 = 0x0018
    public static let trendEnd = 0x00FE

    public static let pageStatus = 0x00
    public static let pageEcho = 0x01
    public static let pageTrend = 0x02
    public static let pageMenu = 0x04
    public static let pagePairing = 0x05
    public static let pageUpload = 0x06
    public static let pageDownload = 0x07

    public static let pageStatusCH2 = 0x10
    public static let pageEchoCH2 = 0x11
    public static let pageTrendCH2 = 0x12
    public static let pageEchoAvgCH2 = 0x15
    public static let pageDownloadCH2 = 0x17

    public static let lenDeviceInfoDensity: UInt16 = 0x0005
    public static let lenDeviceInfoInterface: UInt16 = 0x0007
}
