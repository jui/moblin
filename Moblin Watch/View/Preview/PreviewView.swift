import SwiftUI

private let barsPerDb: Float = 0.3
private let clippingThresholdDb: Float = -1.0
private let redThresholdDb: Float = -8.5
private let yellowThresholdDb: Float = -20
private let zeroThresholdDb: Float = -60

// Approx 60 * 0.3 = 20
private let maxBars = "||||||||||||||||||||"

struct AudioLevelView: View {
    var showBar: Bool
    var level: Float

    private func bars(count: Float) -> Substring {
        let barCount = Int(count.rounded(.toNearestOrAwayFromZero))
        return maxBars.prefix(barCount)
    }

    private func isClipping() -> Bool {
        return level > clippingThresholdDb
    }

    private func clippingText() -> Substring {
        let db = -zeroThresholdDb
        return bars(count: db * barsPerDb)
    }

    private func redText() -> Substring {
        guard level > redThresholdDb else {
            return ""
        }
        let db = level - redThresholdDb
        return bars(count: db * barsPerDb)
    }

    private func yellowText() -> Substring {
        guard level > yellowThresholdDb else {
            return ""
        }
        let db = min(level - yellowThresholdDb, redThresholdDb - yellowThresholdDb)
        return bars(count: db * barsPerDb)
    }

    private func greenText() -> Substring {
        guard level > zeroThresholdDb else {
            return ""
        }
        let db = min(level - zeroThresholdDb, yellowThresholdDb - zeroThresholdDb)
        return bars(count: db * barsPerDb)
    }

    var body: some View {
        HStack(spacing: 1) {
            HStack(spacing: 1) {
                if level.isNaN {
                    Text("Muted")
                        .foregroundColor(.white)
                } else if level == .infinity {
                    Text("Unknown")
                        .foregroundColor(.white)
                } else {
                    if showBar {
                        HStack(spacing: 0) {
                            if isClipping() {
                                Text(clippingText())
                                    .foregroundColor(.red)
                            } else {
                                Text(redText())
                                    .foregroundColor(.red)
                                Text(yellowText())
                                    .foregroundColor(.yellow)
                                Text(greenText())
                                    .foregroundColor(.green)
                            }
                        }
                        .padding([.bottom], 2)
                        .bold()
                    } else {
                        Text(formatAudioLevelDb(level: level))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding([.leading, .trailing], 2)
            .background(Color(white: 0, opacity: 0.6))
            .cornerRadius(5)
            .font(smallFont)
            Image(systemName: "waveform")
                .frame(width: 17, height: 17)
                .font(smallFont)
                .padding([.leading, .trailing], 2)
                .padding([.bottom], showBar ? 2 : 0)
                .foregroundColor(.white)
                .background(Color(white: 0, opacity: 0.6))
                .cornerRadius(5)
        }
        .padding(0)
    }
}

struct TextItemView: View {
    var name: String
    var value: String
    var sensitive: Bool = false
    var color: Color = .gray

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text(replaceSensitive(value: value, sensitive: sensitive))
                .foregroundColor(color)
                .lineLimit(1)
        }
    }
}

struct StreamOverlayTextView: View {
    var text: String
    var textColor: Color

    var body: some View {
        Text(text)
            .foregroundColor(textColor)
            .padding([.leading, .trailing], 2)
            .background(Color(white: 0, opacity: 0.6))
            .cornerRadius(5)
    }
}

struct StreamOverlayIconAndTextView: View {
    var icon: String
    var text: String
    var color: Color = .white
    var textColor: Color = .white

    var body: some View {
        HStack(spacing: 1) {
            StreamOverlayTextView(text: text, textColor: textColor)
                .font(smallFont)
            Image(systemName: icon)
                .frame(width: 17, height: 17)
                .font(smallFont)
                .padding([.leading, .trailing], 2)
                .foregroundColor(color)
                .background(Color(white: 0, opacity: 0.6))
                .cornerRadius(5)
        }
        .padding(0)
    }
}

struct PreviewView: View {
    @EnvironmentObject var model: Model

    var body: some View {
        ZStack {
            if let preview = model.preview {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding([.bottom], 3)
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "tv.slash")
                        Spacer()
                    }
                    Spacer()
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding([.bottom], 3)
            }
            VStack(spacing: 1) {
                Spacer()
                HStack {
                    Spacer()
                    AudioLevelView(showBar: true, level: model.audioLevel)
                }
                HStack {
                    Spacer()
                    StreamOverlayIconAndTextView(
                        icon: "speedometer",
                        text: model.speedAndTotal
                    )
                }
                .padding([.bottom], 4)
            }
            .padding([.leading], 3)
        }
    }
}