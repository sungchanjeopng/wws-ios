import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case main, echo, trend, diagnostics, menu
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .main: "Main"
        case .echo: "Echo"
        case .trend: "Trend"
        case .diagnostics: "Diag"
        case .menu: "Menu"
        }
    }
}

struct BottomNavBarView: View {
    @Binding var selected: AppTab
    var body: some View {
        HStack {
            ForEach(AppTab.allCases) { tab in
                Button(tab.title) { selected = tab }
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 13, weight: selected == tab ? .bold : .regular))
            }
        }
        .padding(.vertical, 10)
    }
}
