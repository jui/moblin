import Collections
import SDWebImageSwiftUI
import SwiftUI

struct LineView: View {
    var post: ChatPost
    var chat: SettingsChat

    private func usernameColor() -> Color {
        if let userColor = post.userColor, let colorNumber = Int(
            userColor.suffix(6),
            radix: 16
        ) {
            let color = RgbColor(
                red: (colorNumber >> 16) & 0xFF,
                green: (colorNumber >> 8) & 0xFF,
                blue: colorNumber & 0xFF
            )
            return color.color()
        } else {
            return chat.usernameColor.color()
        }
    }

    private func backgroundColor() -> Color {
        if chat.backgroundColorEnabled {
            return chat.backgroundColor.color().opacity(0.6)
        } else {
            return .clear
        }
    }

    private func shadowColor() -> Color {
        if chat.shadowColorEnabled {
            return chat.shadowColor.color()
        } else {
            return .clear
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(post.user)
                .foregroundColor(usernameColor())
                .lineLimit(1)
                .padding([.leading], 5)
                .padding([.trailing], 0)
                .bold(chat.boldUsername!)
                .shadow(color: shadowColor(), radius: 0, x: 1.5, y: 1.5)
            Text(":")
                .bold(chat.boldMessage!)
                .shadow(color: shadowColor(), radius: 0, x: 1.5, y: 1.5)
            ForEach(post.segments, id: \.id) { segment in
                Text(" ")
                if let text = segment.text {
                    Text(text)
                        .foregroundColor(chat.messageColor.color())
                        .bold(chat.boldMessage!)
                        .shadow(color: shadowColor(), radius: 0, x: 1.5, y: 1.5)
                }
                if let url = segment.url {
                    if chat.animatedEmotes! {
                        WebImage(url: url)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: CGFloat(chat.fontSize * 2))
                    } else {
                        CacheAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            EmptyView()
                        }
                        .frame(height: CGFloat(chat.fontSize * 2))
                    }
                }
            }
        }
        .font(.system(size: CGFloat(chat.fontSize)))
        .background(backgroundColor())
        .foregroundColor(.white)
        .cornerRadius(5)
    }
}

struct StreamOverlayChatView: View {
    @ObservedObject var model: Model

    func messageText() -> String {
        if !model.isChatConfigured() {
            return "Not configured"
        } else if model.isChatConnected() {
            return String(format: "%.2f m/s", model.chatPostsPerSecond)
        } else {
            return ""
        }
    }

    func messageColor() -> Color {
        if !model.isChatConfigured() {
            return .white
        } else if model.isChatConnected() {
            return .white
        } else {
            return .red
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Spacer()
                StreamOverlayIconAndTextView(
                    icon: "message",
                    text: messageText(),
                    color: messageColor()
                )
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(model.chatPosts) { post in
                        LineView(post: post, chat: model.database.chat!)
                    }
                }
            }
            Spacer()
        }
    }
}
