import SwiftUI

struct BatteryView: View {
    @EnvironmentObject var model: Model

    private func color(level: Double) -> Color {
        if level < 0.2 {
            return .red
        } else if level < 0.4 {
            return .yellow
        } else {
            return .white
        }
    }

    private func width(level: Double) -> Double {
        if level >= 0.0 && level <= 1.0 {
            return 23 * level
        } else {
            return 0
        }
    }

    private func percentage(level: Double) -> String {
        return String(Int(level * 100))
    }

    var body: some View {
        HStack(spacing: 0) {
            if model.database.batteryPercentage! {
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 2)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 12)
                    Text(percentage(level: model.batteryLevel))
                        .foregroundColor(.black)
                        .font(.system(size: 12))
                        .fixedSize()
                        .bold()
                }
            } else {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(.gray)
                    RoundedRectangle(cornerRadius: 1)
                        .foregroundColor(color(level: model.batteryLevel))
                        .padding([.leading], 1)
                        .frame(width: width(level: model.batteryLevel), height: 10)
                }
            }
            Circle()
                .trim(from: 0.0, to: 0.5)
                .rotationEffect(.degrees(-90))
                .foregroundColor(.gray)
                .frame(width: 4)
        }
        .padding([.top], 1)
        .frame(width: 28, height: 13)
    }
}
