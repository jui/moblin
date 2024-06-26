import SwiftUI

struct StreamOverlayIconAndTextView: View {
    var show: Bool
    var icon: String
    var text: String
    var textFirst = false
    var color: Color = .white

    var body: some View {
        if show {
            HStack(spacing: 1) {
                if textFirst {
                    StreamOverlayTextView(text: text)
                        .font(smallFont)
                }
                Image(systemName: icon)
                    .frame(width: 17, height: 17)
                    .font(smallFont)
                    .padding([.leading, .trailing], 2)
                    .foregroundColor(color)
                    .background(backgroundColor)
                    .cornerRadius(5)
                if !textFirst {
                    StreamOverlayTextView(text: text)
                        .font(smallFont)
                }
            }
            .padding(0)
        }
    }
}
