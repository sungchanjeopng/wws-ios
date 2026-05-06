import Foundation

public enum DeviceNameParser {
    public static func isWesswareName(_ name: String) -> Bool {
        let lower = name.lowercased()
        return lower.hasPrefix("w3") || lower.hasPrefix("w2") || lower.contains("we13") || lower.contains("we23") || lower.contains("env") || lower.contains("chipsen")
    }

    public static func displayName(rawName name: String) -> (displayName: String, productName: String, ch1Site: String, ch2Site: String, isInterface: Bool) {
        let lower = name.lowercased()
        let isInterface = lower.hasPrefix("w3") || lower.contains("we13") || lower.contains("env130")
        let productName = isInterface ? "ENV130" : "ENV230"

        let stripped: String
        if lower.hasPrefix("w3") || lower.hasPrefix("w2") {
            stripped = String(name.dropFirst(2))
        } else {
            stripped = ""
        }

        var ch1Site = ""
        var ch2Site = ""
        if stripped.count >= 6 {
            ch1Site = String(stripped.prefix(3))
            ch2Site = String(stripped.dropFirst(3).prefix(3))
        } else if stripped.count >= 3 {
            ch1Site = String(stripped.prefix(3))
        }

        let display: String
        if !ch1Site.isEmpty {
            display = !ch2Site.isEmpty ? "\(productName)  \(ch1Site) / \(ch2Site)" : "\(productName)_\(ch1Site)"
        } else {
            display = productName
        }
        return (display, productName, ch1Site, ch2Site, isInterface)
    }

    public static func signalLevel(rssi: Int) -> Int {
        if rssi >= -55 { return 3 }
        if rssi >= -72 { return 2 }
        return 1
    }
}
