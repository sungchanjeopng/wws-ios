import SwiftUI

struct PairingView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        List {
            Section("Status") {
                Text(app.pairingState.label)
                Text(app.lastEventMessage).font(.caption).foregroundStyle(.secondary)
            }

            Section("Discovered WESSWARE Devices") {
                if app.discoveredDevices.isEmpty {
                    Text("No matching peripherals discovered yet.")
                        .foregroundStyle(.secondary)
                }

                ForEach(app.discoveredDevices) { device in
                    Button {
                        app.connect(to: device)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.displayName).font(.headline)
                            Text(device.advertisedName).font(.caption)
                            Text("RSSI: \(device.rssi) / iOS UUID: \(device.id)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Pairing")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Scan") { app.startScan() }
                Button("Stop") { app.stopScan() }
                Button("Pair") { app.requestPairing() }
            }
        }
    }
}
