import SwiftUI

struct GameOverView: View {
    let score: Int
    let distance: Int
    let coins: Int
    let highScore: Int
    let onRetry: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                VStack(spacing: 10) {
                    statRow(label: "Score", value: "\(score)")
                    statRow(label: "Distance", value: "\(distance)m")
                    statRow(label: "Coins", value: "\(coins)")
                    statRow(label: "High Score", value: "\(highScore)",
                            color: .yellow)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                )

                HStack(spacing: 16) {
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.green.opacity(0.85))
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onMenu) {
                        Text("Menu")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue.opacity(0.85))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
        }
    }

    private func statRow(label: String, value: String,
                         color: Color = .white) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 40)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(minWidth: 220)
    }
}
