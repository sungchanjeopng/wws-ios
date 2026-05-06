import SwiftUI
import WWS2Core

struct MainShellView: View {
    @EnvironmentObject var app: AppViewModel
    var body: some View {
        TabView(selection: $app.selectedTab) {
            MainStatusView().tabItem { Label("Main", systemImage: "gauge") }.tag(0)
            PairingView().tabItem { Label("Pairing", systemImage: "dot.radiowaves.left.and.right") }.tag(1)
            EchoView().tabItem { Label("Echo", systemImage: "waveform.path.ecg") }.tag(2)
            TrendView().tabItem { Label("Trend", systemImage: "chart.xyaxis.line") }.tag(3)
            MenuView().tabItem { Label("Menu", systemImage: "line.3.horizontal") }.tag(4)
        }
    }
}

struct MainStatusView: View {
    @EnvironmentObject var app: AppViewModel
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("WESSWARE").font(.largeTitle.bold())
                if let r = app.lastReading {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Level: \(r.level, specifier: "%.2f")")
                        if let heavy = r.heavyLevel { Text("Heavy: \(heavy, specifier: "%.2f")") }
                        Text("Temp: \(r.temperature, specifier: "%.1f") ℃")
                        Text("Current: \(r.currentMA, specifier: "%.2f") mA")
                        Text("Error: \(r.errorCode)")
                    }.font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    ContentUnavailableView("No device connected", systemImage: "antenna.radiowaves.left.and.right", description: Text("Pairing 탭에서 BLE 장비를 연결하세요."))
                }
                Button("Request Status") { app.requestStatus() }.buttonStyle(.borderedProminent)
            }.padding().navigationTitle("Main")
        }
    }
}

struct PairingView: View {
    @EnvironmentObject var app: AppViewModel
    var body: some View {
        NavigationStack {
            List {
                Section("PIN") {
                    TextField("PIN", text: $app.pin).keyboardType(.numberPad)
                    Button("Send Pairing Request") { app.sendPairingRequest() }
                }
                Section("Devices") {
                    ForEach(app.scannedDevices) { d in
                        Button { app.connect(d) } label: {
                            HStack { VStack(alignment: .leading) { Text(d.rawName); Text(d.type.rawValue).font(.caption) }; Spacer(); Text("RSSI \(d.rssi)") }
                        }
                    }
                }
            }
            .toolbar { Button("Scan") { app.startScan() }; Button("Stop") { app.stopScan() } }
            .navigationTitle("Pair BLE devices")
        }
    }
}

struct EchoView: View {
    @EnvironmentObject var app: AppViewModel
    var body: some View { NavigationStack { VStack { if let e = app.lastEcho { Text("Echo samples: \(e.rawWave.count)"); Text("EEA: \(e.eeaD)") } else { ContentUnavailableView("No echo", systemImage: "waveform") } }.navigationTitle("Echo") } }
}
struct TrendView: View { var body: some View { NavigationStack { ContentUnavailableView("Trend", systemImage: "chart.xyaxis.line", description: Text("Trend stream parser는 WWS2Core에 포팅 완료. 실제 장비 프레임으로 UI 연결 필요.")) } } }
struct MenuView: View { var body: some View { NavigationStack { List { NavigationLink("Upload / OTA") { Text("OTA frame helpers ready. 실제 펌웨어 파일 picker 연결 필요.") }; NavigationLink("Download / CSV") { Text("Trend parser ready. fileExporter 연결 필요.") }; NavigationLink("Diagnostics") { Text("Diag parser ready") } }.navigationTitle("Menu") } } }
