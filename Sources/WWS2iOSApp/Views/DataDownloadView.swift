import SwiftUI

struct DataDownloadView: View {
    @EnvironmentObject private var app: AppViewModel

    private var previewText: String {
        app.exportPreviewText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Download").font(.title2.bold())
            Text(app.downloadState.label)
                .foregroundStyle(.secondary)
            Button("Prepare CSV Preview") {
                app.beginDownloadPlaceholder()
            }

            if previewText.isEmpty {
                Text("CSV preview appears here after trend or status data is available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CSV Preview")
                        .font(.headline)
                    ScrollView {
                        Text(previewText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 260)
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Text("CSV is generated locally in pure Swift. ShareLink or FileExporter can be added later from a real Xcode app project.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
