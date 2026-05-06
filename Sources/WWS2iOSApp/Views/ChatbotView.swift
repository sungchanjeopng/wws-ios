import SwiftUI

struct ChatbotView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("AI Chatbot").font(.title2.bold())
            Text("Do not embed API keys in the app target. A server-side proxy remains the safer integration path.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
