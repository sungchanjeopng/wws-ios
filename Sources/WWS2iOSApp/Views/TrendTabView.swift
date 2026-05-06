import SwiftUI

struct TrendTabView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        List {
            Section("Trend") {
                if app.trendRecords.isEmpty {
                    Text("Trend records appear here after trend frames are parsed.")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(app.trendRecords.enumerated()), id: \.offset) { _, record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.timestampLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text(String(format: "DST %.2f", record.dst))
                            Spacer()
                            Text(String(format: "%.1f C", record.temperature))
                        }
                    }
                }
            }
        }
        .navigationTitle("Trend")
    }
}
