import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showSettings = false

    var body: some View {
        HStack {
            Button(action: {
                viewModel.newChat()
            }) {
                Image(systemName: "plus")
                Text("New Chat")
            }

            Button(action: {
                viewModel.saveChat()
            }) {
                Image(systemName: "square.and.arrow.down")
                Text("Save Chat")
            }

            Button(action: {
                viewModel.clearChat()
            }) {
                Image(systemName: "trash")
                Text("Clear Chat")
            }

            Spacer()

            Button(action: {
                showSettings.toggle()
            }) {
                Image(systemName: "gear")
                Text("Settings")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .padding()
    }
}
