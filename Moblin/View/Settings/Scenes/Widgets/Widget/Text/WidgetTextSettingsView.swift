import PhotosUI
import SwiftUI

struct WidgetTextSettingsView: View {
    @EnvironmentObject var model: Model
    var widget: SettingsWidget
    @State var backgroundColor: Color
    @State var foregroundColor: Color

    private func submitFormatString(value: String) {
        widget.text.formatString = value
        model.store()
        model.resetSelectedScene(changeScene: false)
    }

    var body: some View {
        Section {
            TextEditNavigationView(
                title: "Format",
                value: widget.text.formatString,
                onSubmit: submitFormatString,
                footers: [
                    String(localized: "{time} - Show time as HH:MM:SS"),
                    String(localized: "{speed} - Show speed (if Settings → Location is enabled)"),
                    String(localized: "{altitude} - Show altitude (if Settings → Location is enabled)"),
                    String(localized: "{distance} - Show distance (if Settings → Location is enabled)"),
                    String(localized: "{bitrateAndTotal} - Show bitrate and total number of bytes sent"),
                    String(localized: "{debugOverlay} - Show debug overlay (if enabled)"),
                ]
            )
            Toggle(isOn: Binding(get: {
                !widget.text.clearBackgroundColor!
            }, set: { value in
                widget.text.clearBackgroundColor = !value
                model.store()
                model.resetSelectedScene(changeScene: false)
            })) {
                ColorPicker("Background", selection: $backgroundColor, supportsOpacity: false)
                    .onChange(of: backgroundColor) { _ in
                        guard let color = backgroundColor.toRgb() else {
                            return
                        }
                        widget.text.backgroundColor = color
                        model.store()
                        model.resetSelectedScene(changeScene: false)
                    }
            }
            Toggle(isOn: Binding(get: {
                !widget.text.clearForegroundColor!
            }, set: { value in
                widget.text.clearForegroundColor = !value
                model.store()
                model.resetSelectedScene(changeScene: false)
            })) {
                ColorPicker("Foreground", selection: $foregroundColor, supportsOpacity: false)
                    .onChange(of: foregroundColor) { _ in
                        guard let color = foregroundColor.toRgb() else {
                            return
                        }
                        widget.text.foregroundColor = color
                        model.store()
                        model.resetSelectedScene(changeScene: false)
                    }
            }
        }
    }
}
