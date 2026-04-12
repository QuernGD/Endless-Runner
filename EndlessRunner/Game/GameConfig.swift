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

    // Coins
    static let coinRadius: CGFloat = 12
    static let coinValue: Int = 10

    // Input
    static let swipeThreshold: CGFloat = 30

    // Ground
    static let groundHeight: CGFloat = 80

    // Scoring
    static let scorePerSecond: CGFloat = 10
}
