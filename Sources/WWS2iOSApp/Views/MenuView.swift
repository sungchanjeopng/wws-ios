import SwiftUI

struct MenuView: View {
    var body: some View {
        List {
            NavigationLink("Pairing") { PairingView() }
            NavigationLink("Data Download") { DataDownloadView() }
            NavigationLink("Upload") { UploadView() }
            NavigationLink("Chatbot") { ChatbotView() }
        }
        .navigationTitle("Menu")
    }
}
