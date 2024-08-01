import Foundation

enum TextFormatPart {
    case text(String)
    case newLine
    case clock
    case bitrateAndTotal
    case debugOverlay
    case speed
    case altitude
    case distance
    case timer
    case conditions
    case temperature
    case country
    case countryFlag
    case city
    case checkbox
}

class TextFormatLoader {
    private var format: String = ""
    private var parts: [TextFormatPart] = []
    private var index: String.Index!
    private var textStartIndex: String.Index!

    func load(format inputFormat: String) -> [TextFormatPart] {
        format = inputFormat.replacing("\\n", with: "\n")
        parts = []
        index = format.startIndex
        textStartIndex = format.startIndex
        while index < format.endIndex {
            switch format[index] {
            case "{":
                let formatFromIndex = format[index ..< format.endIndex].lowercased()
                if formatFromIndex.hasPrefix("{time}") {
                    loadItem(part: .clock, offsetBy: 6)
                } else if formatFromIndex.hasPrefix("{bitrateandtotal}") {
                    loadItem(part: .bitrateAndTotal, offsetBy: 17)
                } else if formatFromIndex.hasPrefix("{debugoverlay}") {
                    loadItem(part: .debugOverlay, offsetBy: 14)
                } else if formatFromIndex.hasPrefix("{speed}") {
                    loadItem(part: .speed, offsetBy: 7)
                } else if formatFromIndex.hasPrefix("{altitude}") {
                    loadItem(part: .altitude, offsetBy: 10)
                } else if formatFromIndex.hasPrefix("{distance}") {
                    loadItem(part: .distance, offsetBy: 10)
                } else if formatFromIndex.hasPrefix("{timer}") {
                    loadItem(part: .timer, offsetBy: 7)
                } else if formatFromIndex.hasPrefix("{conditions}") {
                    loadItem(part: .conditions, offsetBy: 12)
                } else if formatFromIndex.hasPrefix("{temperature}") {
                    loadItem(part: .temperature, offsetBy: 13)
                } else if formatFromIndex.hasPrefix("{country}") {
                    loadItem(part: .country, offsetBy: 9)
                } else if formatFromIndex.hasPrefix("{countryflag}") {
                    loadItem(part: .countryFlag, offsetBy: 13)
                } else if formatFromIndex.hasPrefix("{city}") {
                    loadItem(part: .city, offsetBy: 6)
                } else if formatFromIndex.hasPrefix("{checkbox}") {
                    loadItem(part: .checkbox, offsetBy: 10)
                } else {
                    index = format.index(after: index)
                }
            case "\n":
                loadItem(part: .newLine, offsetBy: 1)
            default:
                index = format.index(after: index)
            }
        }
        appendTextIfPresent()
        return parts
    }

    private func appendTextIfPresent() {
        if textStartIndex < index {
            parts.append(.text(String(format[textStartIndex ..< index])))
        }
    }

    private func loadItem(part: TextFormatPart, offsetBy: Int) {
        appendTextIfPresent()
        parts.append(part)
        index = format.index(index, offsetBy: offsetBy)
        textStartIndex = index
    }
}

func loadTextFormat(format: String) -> [TextFormatPart] {
    return TextFormatLoader().load(format: format)
}