import CoreGraphics
import Foundation

/// All gameplay tunables live here.
enum GameConfig {
    // Lanes
    static let laneCount: Int = 3

    // Player
    static let playerXFraction: CGFloat = 0.2
    static let playerWidth: CGFloat = 30
    static let playerHeight: CGFloat = 50
    static let playerSlideHeight: CGFloat = 25

    // Scroll speed
    static let baseScrollSpeed: CGFloat = 300
    static let maxScrollSpeed: CGFloat = 600
    static let speedIncreaseInterval: TimeInterval = 30
    static let speedIncreaseRate: CGFloat = 1.08

    // Jump
    static let jumpDuration: TimeInterval = 0.5
    static let jumpHeight: CGFloat = 80

    // Slide
    static let slideDuration: TimeInterval = 0.6

    // Lane switching
    static let laneSwitchDuration: TimeInterval = 0.15

    // Obstacles
    static let obstacleWidth: CGFloat = 40
    static let lowBarrierHeight: CGFloat = 40
    static let tallBarrierHeight: CGFloat = 80
    static let fullBlockHeight: CGFloat = 120
    static let trainLength: CGFloat = 200
    static let minObstacleSpacing: CGFloat = 250
    /// Additional spacing that gets subtracted as speed climbs (never go
    /// below `minObstacleSpacing`).
    static let maxObstacleSpacingBonus: CGFloat = 120

    // Coins
    static let coinRadius: CGFloat = 12
    static let coinValue: Int = 10

    // Input — a swipe is only registered once the touch has moved at least
    // `swipeThreshold` points from its origin. Anything shorter is treated
    // as a tap and triggers a jump (accessibility affordance).
    static let swipeThreshold: CGFloat = 15

    // Ground
    static let groundHeight: CGFloat = 80

    // Difficulty timing (seconds since run start)
    static let difficultyStageB: TimeInterval = 10
    static let difficultyStageCD: TimeInterval = 30
    static let difficultyStageE: TimeInterval = 60

    // Feedback
    /// Horizontal distance at which an obstacle counts as a "near miss".
    static let nearMissDistance: CGFloat = 10
    /// Screen shake magnitude on death.
    static let deathShakeMagnitude: CGFloat = 18
}
