import SwiftUI
import WWS2Core

@main
struct WESSWAREApp: App {
    @StateObject private var app = AppViewModel()
    var body: some Scene {
        WindowGroup { MainShellView().environmentObject(app) }
    }
}
