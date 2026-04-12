import CoreGraphics
import Foundation

/// Tracks score, coins and persists the high score in UserDefaults.
final class ScoreManager {
    private static let highScoreKey = "EndlessRunner.highScore"
    private static let highCoinsKey = "EndlessRunner.highCoins"

    private(set) var distance: CGFloat = 0
    private(set) var coins: Int = 0

    var score: Int { Int(distance) + coins * GameConfig.coinValue }

    var highScore: Int {
        get { UserDefaults.standard.integer(forKey: Self.highScoreKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.highScoreKey) }
    }

    var highCoins: Int {
        get { UserDefaults.standard.integer(forKey: Self.highCoinsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.highCoinsKey) }
    }

    func reset() {
        distance = 0
        coins = 0
    }

    func addDistance(_ delta: CGFloat) {
        distance += delta
    }

    func collectCoin() {
        coins += 1
    }

    /// Commit the current run to the persisted high scores.
    func commitHighScores() {
        if score > highScore {
            highScore = score
        }
        if coins > highCoins {
            highCoins = coins
        }
    }
}
