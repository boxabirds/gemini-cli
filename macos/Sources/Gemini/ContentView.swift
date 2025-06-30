import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var inputText = ""

    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            VStack {
                ToolbarView(viewModel: viewModel)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
                        }
                    }
                    .padding()
                }

                // Input area
                HStack {
                    TextField("Type a message...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit(sendMessage)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(inputText.isEmpty)
                }
                .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    /// Sends the current input text as a new message.
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        viewModel.sendMessage(text: inputText)
        inputText = ""
    }
}
