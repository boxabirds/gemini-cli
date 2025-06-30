import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(message.text)
                    .padding(10)
                    .background(Color(NSColor.lightGray))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                Spacer()
            }
        }
    }
}
