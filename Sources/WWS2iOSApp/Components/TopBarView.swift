import SwiftUI

struct TopBarView: View {
    let title: String
    let isConnected: Bool
    var subtitle: String = ""

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Circle().fill(isConnected ? .green : .red).frame(width: 10, height: 10)
            Text(isConnected ? "Connected" : "Disconnected").font(.caption)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
