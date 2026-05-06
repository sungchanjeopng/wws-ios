import SwiftUI

struct UploadView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Firmware Upload").font(.title2.bold())
            Text(app.uploadState.label)
                .foregroundStyle(.secondary)
            Button("Prepare OTA Placeholder") {
                app.beginUploadPlaceholder()
            }
            Text("OTA stays disabled until chunk sizing and acknowledgements are validated on a physical iPhone and WESSWARE device.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
