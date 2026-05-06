import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Main Status").font(.title2.bold())

            if let reading = app.currentReading {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow { Text("Level"); Text(String(format: "%.2f m", reading.level)) }
                    GridRow { Text("Heavy Level"); Text(String(format: "%.2f m", reading.heavyLevel)) }
                    GridRow { Text("Temp"); Text(String(format: "%.1f C", reading.temperature)) }
                    GridRow { Text("Current"); Text(String(format: "%.2f mA", reading.currentMA)) }
                    GridRow { Text("Error"); Text("\(reading.errorCode)") }
                }
            } else {
                Text("Status values appear here after a status frame is parsed.")
                    .foregroundStyle(.secondary)
            }

            Text(app.lastEventMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
