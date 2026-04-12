import SwiftUI
import SpriteKit

/// App-level view that switches between the main menu, the live gameplay
/// scene and the game-over screen.
struct ContentView: View {
    enum Screen: Equatable {
        case menu
        case playing
        case gameOver(score: Int, distance: Int, coins: Int, highScore: Int)
    }

    @State private var screen: Screen = .menu
    @State private var sceneHolder = GameSceneHolder()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch screen {
            case .menu:
                MainMenuView(onPlay: startGame)
            case .playing:
                SpriteView(scene: sceneHolder.scene,
                           options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
                    .id(sceneHolder.sceneID)
            case let .gameOver(score, distance, coins, highScore):
                ZStack {
                    SpriteView(scene: sceneHolder.scene,
                               options: [.ignoresSiblingOrder])
                        .ignoresSafeArea()
                        .id(sceneHolder.sceneID)
                    GameOverView(score: score,
                                 distance: distance,
                                 coins: coins,
                                 highScore: highScore,
                                 onRetry: startGame,
                                 onMenu: { screen = .menu })
                }
            }
        }
        .onAppear {
            sceneHolder.onEnd = { score, distance, coins, highScore in
                screen = .gameOver(score: score,
                                   distance: distance,
                                   coins: coins,
                                   highScore: highScore)
            }
        }
    }

    private func startGame() {
        sceneHolder.newScene()
        screen = .playing
    }
}

/// Holds the active GameScene so SwiftUI refreshes pick up new instances.
final class GameSceneHolder: GameSceneDelegate {
    var scene: GameScene
    var sceneID: UUID = UUID()

    var onEnd: ((Int, Int, Int, Int) -> Void)?

    init() {
        self.scene = GameSceneHolder.makeScene()
        self.scene.gameDelegate = self
    }

    private static func makeScene() -> GameScene {
        let s = GameScene(size: CGSize(width: 390, height: 844))
        s.scaleMode = .resizeFill
        return s
    }

    func newScene() {
        let s = GameSceneHolder.makeScene()
        s.gameDelegate = self
        self.scene = s
        self.sceneID = UUID()
    }

    func gameSceneDidEnd(score: Int, distance: Int, coins: Int, highScore: Int) {
        onEnd?(score, distance, coins, highScore)
    }
}
