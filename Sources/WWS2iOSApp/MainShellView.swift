import SwiftUI

struct MainShellView: View {
    @EnvironmentObject private var app: AppViewModel
    @State private var selectedTab: AppTab = .main

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopBarView(title: "WESSWARE", isConnected: app.isConnected, subtitle: app.pairingState.label)

                Group {
                    switch selectedTab {
                    case .main:
                        MainTabView()
                    case .echo:
                        EchoTabView()
                    case .trend:
                        TrendTabView()
                    case .diagnostics:
                        DiagnosticsView()
                    case .menu:
                        MenuView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                BottomNavBarView(selected: $selectedTab)
            }
        }
    }
}
