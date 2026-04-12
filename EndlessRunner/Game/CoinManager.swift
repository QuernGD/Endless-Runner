import SpriteKit

final class CoinNode: SKShapeNode {
    var collected: Bool = false
}

/// Spawns coins in lines and arcs between obstacle groups.
final class CoinManager {
    private weak var scene: SKScene?
    private(set) var active: [CoinNode] = []
    private var laneConfig: LaneConfig
    private var distanceSinceLastSpawn: CGFloat = 0
    private var nextSpawnGap: CGFloat = 180

    init(scene: SKScene, laneConfig: LaneConfig) {
        self.scene = scene
        self.laneConfig = laneConfig
    }

    func updateLaneConfig(_ cfg: LaneConfig) {
        self.laneConfig = cfg
    }

    func reset() {
        for c in active { c.removeFromParent() }
        active.removeAll()
        distanceSinceLastSpawn = 0
        nextSpawnGap = 180
    }

    func update(dt: CGFloat, scrollSpeed: CGFloat) {
        let dx = scrollSpeed * dt
        for c in active {
            c.position.x -= dx
        }
        active.removeAll { coin in
            if coin.position.x < -40 || coin.collected {
                coin.removeFromParent()
                return true
            }
            return false
        }

        distanceSinceLastSpawn += dx
        if distanceSinceLastSpawn >= nextSpawnGap {
            distanceSinceLastSpawn = 0
            nextSpawnGap = CGFloat.random(in: 180...320)
            spawnPattern()
        }
    }

    private func spawnPattern() {
        guard let scene else { return }
        let patternType = Int.random(in: 0..<3)
        let startX = scene.size.width + 40
        switch patternType {
        case 0:
            // Straight line in a single lane.
            let lane = Int.random(in: 0..<GameConfig.laneCount)
            let count = Int.random(in: 3...5)
            for i in 0..<count {
                spawnCoin(x: startX + CGFloat(i) * 40,
                          y: laneConfig.yForLane(lane))
            }
        case 1:
            // Upward arc 0 -> 1 -> 2
            let lanes = [0, 1, 2]
            for (i, lane) in lanes.enumerated() {
                spawnCoin(x: startX + CGFloat(i) * 50,
                          y: laneConfig.yForLane(lane))
            }
        default:
            // Downward arc 2 -> 1 -> 0
            let lanes = [2, 1, 0]
            for (i, lane) in lanes.enumerated() {
                spawnCoin(x: startX + CGFloat(i) * 50,
                          y: laneConfig.yForLane(lane))
            }
        }
    }

    private func spawnCoin(x: CGFloat, y: CGFloat) {
        guard let scene else { return }
        let coin = CoinNode(circleOfRadius: GameConfig.coinRadius)
        coin.fillColor = .systemYellow
        coin.strokeColor = SKColor(white: 0.9, alpha: 1)
        coin.lineWidth = 1.5
        coin.position = CGPoint(x: x, y: y)
        coin.zPosition = 25
        scene.addChild(coin)
        active.append(coin)
    }

    /// Returns the number of coins collected and removes them from the scene.
    func collectOverlapping(player: CGRect) -> Int {
        var collectedCount = 0
        for coin in active where !coin.collected {
            let r = GameConfig.coinRadius
            let coinRect = CGRect(x: coin.position.x - r,
                                  y: coin.position.y - r,
                                  width: r * 2,
                                  height: r * 2)
            if player.intersects(coinRect) {
                coin.collected = true
                collectedCount += 1
                // Brief pop animation.
                let scale = SKAction.scale(to: 1.8, duration: 0.1)
                let fade = SKAction.fadeOut(withDuration: 0.1)
                coin.run(SKAction.group([scale, fade]))
            }
        }
        return collectedCount
    }
}
