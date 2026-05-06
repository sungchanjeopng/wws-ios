import SwiftUI

struct EchoTabView: View {
    @EnvironmentObject private var app: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Echo").font(.title2.bold())

            if let echo = app.latestEcho {
                Text(String(format: "Level %.2f m / EEA-D %d", echo.levelMeters, echo.eeaD))
                Text("Wave samples: raw \(echo.rawWave.count), interpolated \(echo.wave.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SimpleWavePreview(values: Array(echo.wave.prefix(80)))
                    .frame(height: 160)
            } else {
                Text("An echo waveform preview appears here after a parsed density or interface echo frame.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SimpleWavePreview: View {
    let values: [Double]

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                guard let minValue = values.min(), let maxValue = values.max(), maxValue > minValue else { return }
                for (idx, value) in values.enumerated() {
                    let x = proxy.size.width * CGFloat(idx) / CGFloat(max(values.count - 1, 1))
                    let normalized = (value - minValue) / (maxValue - minValue)
                    let y = proxy.size.height * CGFloat(1.0 - normalized)
                    if idx == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(.blue, lineWidth: 2)
        }
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
