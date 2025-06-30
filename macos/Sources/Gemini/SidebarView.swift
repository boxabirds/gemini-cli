import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var currentPath: String

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        _currentPath = State(initialValue: FileManager.default.homeDirectoryForCurrentUser.path)
    }

    var body: some View {
        List {
            Section(header: Text("Chats")) {
                ForEach(viewModel.savedChats, id: \.self) { chatURL in
                    Text(chatURL.lastPathComponent)
                }
            }

            Section(header: Text("Files")) {
                Button("Up") {
                    let parentPath = URL(fileURLWithPath: currentPath).deletingLastPathComponent().path
                    currentPath = parentPath
                    viewModel.loadFiles(at: currentPath)
                }
                ForEach(viewModel.files, id: \.self) { file in
                    HStack {
                        Text(file)
                        Spacer()
                        Button(action: {
                            let fullPath = URL(fileURLWithPath: currentPath).appendingPathComponent(file).path
                            if let content = viewModel.fileSystemService.readFile(at: fullPath) {
                                viewModel.sendMessage(text: "File: \(file)\n\n\(content)")
                            }
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    .onTapGesture {
                        let fullPath = URL(fileURLWithPath: currentPath).appendingPathComponent(file).path
                        var isDirectory: ObjCBool = false
                        if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                            currentPath = fullPath
                            viewModel.loadFiles(at: currentPath)
                        }
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
}
