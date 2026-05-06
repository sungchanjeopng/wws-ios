import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        List {
            Section("Density Diagnostics") {
                if let diag = app.densityDiag {
                    Text(String(format: "Temp %.1f C", diag.temperature))
                    Text(String(format: "Current %.2f mA", diag.currentMA))
                    Text("Damping \(diag.damping)")
                    Text("Pipe \(diag.pipeDia)")
                    Text("Error \(diag.errorCode)")
                } else {
                    Text("Waiting for a density diagnostic frame.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Interface Diagnostics") {
                if let diag = app.interfaceDiag {
                    Text(String(format: "Temp %.1f C", diag.temperature))
                    Text(String(format: "Current %.2f mA", diag.currentMA))
                    Text("Freq \(diag.freqLabel)")
                    Text(String(format: "Offset %.2f", diag.offset))
                    Text("Relay \(diag.relayOn ? "ON" : "OFF")")
                } else {
                    Text("Waiting for an interface diagnostic frame.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Diagnostics")
    }
}
