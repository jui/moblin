import SwiftUI

private struct Attribution {
    let name: String
    let text: [String]
}

private let soundAttributions: [Attribution] = [
    Attribution(
        name: "Boing",
        text: [
            "Boing.wav by juskiddink",
            "-- https://freesound.org/s/140867/",
            "-- License: Attribution 4.0",
        ]
    ),
    Attribution(
        name: "Cash register",
        text: [
            "Cash Register by kiddpark",
            "-- https://freesound.org/s/201159/",
            "-- License: Attribution 4.0",
        ]
    ),
    Attribution(
        name: "Coin dropping",
        text: [
            "Coin dropping.wav by Jace",
            "-- https://freesound.org/s/17502/",
            "-- License: Creative Commons 0",
        ]
    ),
    Attribution(
        name: "Dingaling",
        text: [
            "dingaling by morrisjm",
            "-- https://freesound.org/s/268756/",
            "-- License: Attribution 4.0",
        ]
    ),
    Attribution(
        name: "Fart",
        text: [
            "FART.aif by Manicciola",
            "-- https://freesound.org/s/121783/",
            "-- License: Creative Commons 0",
        ]
    ),
    Attribution(
        name: "Fart 2",
        text: [
            "Fart sound.wav by aditwayer",
            "-- https://freesound.org/s/520671/",
            "-- License: Creative Commons 0",
        ]
    ),
    Attribution(
        name: "Level up",
        text: [
            "320655__rhodesmas__level-up-01.mp3 by shinephoenixstormcrow",
            "-- https://freesound.org/s/337049/",
            "-- License: Attribution 3.0",
        ]
    ),
    Attribution(
        name: "Notification",
        text: [
            "Message Notification 4 by AnthonyRox",
            "-- https://freesound.org/s/740423/",
            "-- License: Creative Commons 0",
        ]
    ),
    Attribution(
        name: "Notification 2",
        text: [
            "notification2-freesound.wav by Thoribass",
            "-- https://freesound.org/s/254819/",
            "-- License: Attribution 4.0",
        ]
    ),
    Attribution(
        name: "SFX magic",
        text: [
            "SFX Magic by renatalmar",
            "-- https://freesound.org/s/264981/",
            "-- License: Creative Commons 0",
        ]
    ),
    Attribution(
        name: "Silence",
        text: [
            "C0000_silence5sec.mp3 by thanvannispen",
            "-- https://freesound.org/s/107061/",
            "-- License: Attribution 4.0",
        ]
    ),
    Attribution(
        name: "Whoosh",
        text: [
            "Whoosh by qubodup",
            "-- https://freesound.org/s/60013/",
            "-- License: Creative Commons 0",
        ]
    ),
]

private let imageAttributions: [Attribution] = [
    Attribution(
        name: "-100",
        text: [
            "Credit Richie Velasquez ",
            "https://www.deladeso.com/",
        ]
    ),
]

private struct AboutAttributionsSoundsSettingsView: View {
    var body: some View {
        ScrollView {
            HStack {
                LazyVStack(alignment: .leading) {
                    ForEach(soundAttributions, id: \.name) { attribution in
                        Text(attribution.name)
                            .font(.title2)
                            .padding([.top])
                        VStack(alignment: .leading) {
                            ForEach(attribution.text, id: \.self) { line in
                                Text(line)
                            }
                        }
                        .padding([.top, .leading], 5)
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .navigationTitle("Sounds")
    }
}

private struct AboutAttributionsImagesSettingsView: View {
    var body: some View {
        ScrollView {
            HStack {
                LazyVStack(alignment: .leading) {
                    ForEach(imageAttributions, id: \.name) { attribution in
                        Text(attribution.name)
                            .font(.title2)
                            .padding([.top])
                        VStack(alignment: .leading) {
                            ForEach(attribution.text, id: \.self) { line in
                                Text(line)
                            }
                        }
                        .padding([.top, .leading], 5)
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .navigationTitle("Images")
    }
}

struct AboutAttributionsSettingsView: View {
    var body: some View {
        Form {
            NavigationLink(destination: AboutAttributionsSoundsSettingsView()) {
                Text("Sounds")
            }
            NavigationLink(destination: AboutAttributionsImagesSettingsView()) {
                Text("Images")
            }
        }
        .navigationTitle("Attributions")
    }
}
