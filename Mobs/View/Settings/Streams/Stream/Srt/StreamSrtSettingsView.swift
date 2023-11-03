import SwiftUI

struct StreamSrtSettingsView: View {
    @EnvironmentObject var model: Model
    var stream: SettingsStream

    func submitLatency(value: String) {
        guard let latency = Int32(value) else {
            return
        }
        guard latency >= 0 else {
            return
        }
        stream.srt.latency = latency
        model.storeAndReloadStreamIfEnabled(stream: stream)
    }

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: TextEditView(
                    title: "Latency",
                    value: String(stream.srt.latency),
                    onSubmit: submitLatency,
                    footer: Text(
                        """
                        Zero or more milliseconds. Any latency parameter given in the URL \
                        overrides this value.
                        """
                    )
                )) {
                    TextItemView(name: "Latency", value: String(stream.srt.latency))
                }
                Toggle("Big packets", isOn: Binding(get: {
                    stream.srt.mpegtsPacketsPerPacket == 7
                }, set: { value in
                    if value {
                        stream.srt.mpegtsPacketsPerPacket = 7
                    } else {
                        stream.srt.mpegtsPacketsPerPacket = 6
                    }
                    model.storeAndReloadStreamIfEnabled(stream: stream)
                }))
                Toggle("Adaptive bitrate", isOn: Binding(get: {
                    stream.adaptiveBitrate
                }, set: { value in
                    stream.adaptiveBitrate = value
                    model.storeAndReloadStreamIfEnabled(stream: stream)
                }))
            } footer: {
                VStack(alignment: .leading) {
                    Text("Adaptive bitrate is experimental.")
                    Text("")
                    Text(
                        """
                        Big packets means 7 MPEG-TS packets per SRT packet, 6 otherwise, \
                        which sometimes makes Android hotspot work.
                        """
                    )
                }
            }
        }
        .navigationTitle("SRT(LA)")
    }
}
