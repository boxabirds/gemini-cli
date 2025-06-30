import SwiftUI

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey = ""

    var body: some View {
        Form {
            Section(header: Text("API Key")) {
                TextField("Enter your API key", text: $apiKey)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
