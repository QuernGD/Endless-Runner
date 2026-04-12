import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void

    private var highScore: Int {
        UserDefaults.standard.integer(forKey: "EndlessRunner.highScore")
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.62, green: 0.84, blue: 0.97),
                Color(red: 0.32, green: 0.54, blue: 0.78)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text("RUNNER")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)

                VStack(spacing: 6) {
                    Text("High Score")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(highScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                }

                Spacer()

                Button(action: onPlay) {
                    Text("Tap to Play")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.35))
                        )
                }
                .buttonStyle(.plain)

                Text("Swipe to move · Up: Jump · Down: Slide")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 40)
            }
            .padding()
        }
    }
}
