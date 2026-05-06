import SwiftUI

@main
struct WWS2iOSApp: App {
    @StateObject private var appViewModel = AppViewModel.live()

    var body: some Scene {
        WindowGroup {
            MainShellView()
                .environmentObject(appViewModel)
        }
    }
}
