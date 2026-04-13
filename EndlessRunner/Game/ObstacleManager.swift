import SpriteKit

enum ObstacleKind {
    case lowBarrier   // jump over
    case tallBarrier  // slide under
    case fullBlock    // switch lanes
    case train        // long block, switch lanes
}

/// Represents a live obstacle on the scene.
final class ObstacleNode: SKSpriteNode {
    var kind: ObstacleKind = .lowBarrier
    var lane: Int = 0
    /// True once the player's X has moved past this obstacle without hitting
    /// it. Used to avoid reporting the same near-miss multiple times.
    var passed: Bool = false
    /// True once a near-miss has been announced for this obstacle.
    var nearMissReported: Bool = false
}

/// Five hand-authored obstacle patterns. Each is parameterised over the set
/// of available lanes so the placement is symmetric.
enum ObstaclePattern: CaseIterable {
    case a  // single low barrier
    case b  // two adjacent low barriers
    case c  // tall + low in different lanes
    case d  // center full block + low on one side
    case e  // train in one lane
}

/// Spawns and manages obstacles. Tracks active nodes for manual collision.
final class ObstacleManager {
    private weak var scene: SKScene?
    private(set) var active: [ObstacleNode] = []
    private var laneConfig: LaneConfig
    private var distanceSinceLastSpawn: CGFloat = 0
    private var nextSpawnGap: CGFloat = GameConfig.minObstacleSpacing + GameConfig.maxObstacleSpacingBonus
    /// Seconds since the current run started; drives the difficulty curve.
    var runElapsed: TimeInterval = 0

    init(scene: SKScene, laneConfig: LaneConfig) {
        self.scene = scene
        self.laneConfig = laneConfig
    }

    func updateLaneConfig(_ cfg: LaneConfig) {
        self.laneConfig = cfg
    }

    func reset() {
        for o in active { o.removeFromParent() }
        active.removeAll()
        distanceSinceLastSpawn = 0
        nextSpawnGap = GameConfig.minObstacleSpacing + 120
        runElapsed = 0
    }

    // MARK: - Update

    func update(dt: CGFloat, scrollSpeed: CGFloat) {
        runElapsed += TimeInterval(dt)
        let dx = scrollSpeed * dt
        for o in active {
            o.position.x -= dx
        }
        // Remove off-screen.
        active.removeAll { obstacle in
            if obstacle.position.x + obstacle.size.width / 2 < -100 {
                obstacle.removeFromParent()
                return true
            }
            return false
        }

        distanceSinceLastSpawn += dx
        if distanceSinceLastSpawn >= nextSpawnGap {
            distanceSinceLastSpawn = 0
            nextSpawnGap = currentSpawnGap()
            spawnPattern(pickPattern())
        }
    }

    // MARK: - Difficulty curve

    private func currentSpawnGap() -> CGFloat {
        // Spacing shrinks smoothly from +bonus down to the minimum across the
        // first 90 seconds of a run, then jitters a little so patterns stay
        // unpredictable.
        let t = min(1, CGFloat(runElapsed) / 90)
        let bonus = GameConfig.maxObstacleSpacingBonus * (1 - t)
        let jitter = CGFloat.random(in: 0...60)
        return GameConfig.minObstacleSpacing + bonus + jitter
    }

    private var unlockedPatterns: [ObstaclePattern] {
        if runElapsed < GameConfig.difficultyStageB {
            return [.a]
        } else if runElapsed < GameConfig.difficultyStageCD {
            return [.a, .a, .b]
        } else if runElapsed < GameConfig.difficultyStageE {
            return [.a, .b, .b, .c, .d]
        } else {
            return [.a, .b, .c, .c, .d, .d, .e]
        }
    }

    private func pickPattern() -> ObstaclePattern {
        let pool = unlockedPatterns
        let idx = Int.random(in: 0..<pool.count)
        return pool[idx]
    }

    // MARK: - Spawning

    private func spawnPattern(_ pattern: ObstaclePattern) {
        guard let scene else { return }
        let baseX = scene.size.width + GameConfig.obstacleWidth
        switch pattern {
        case .a:
            let lane = Int.random(in: 0..<GameConfig.laneCount)
            spawn(kind: .lowBarrier, lane: lane, x: baseX)

        case .b:
            // Two adjacent low barriers → one lane is forced.
            let start = Int.random(in: 0..<(GameConfig.laneCount - 1))
            spawn(kind: .lowBarrier, lane: start, x: baseX)
            spawn(kind: .lowBarrier, lane: start + 1, x: baseX + 12)

        case .c:
            // Tall + low in different lanes. Pick two distinct lanes.
            var lanes = Array(0..<GameConfig.laneCount).shuffled()
            let tallLane = lanes.removeFirst()
            let lowLane = lanes.removeFirst()
            spawn(kind: .tallBarrier, lane: tallLane, x: baseX)
            spawn(kind: .lowBarrier, lane: lowLane, x: baseX + 20)

        case .d:
            // Full block in center + low on one side; the remaining side
            // stays clear.
            let center = GameConfig.laneCount / 2
            spawn(kind: .fullBlock, lane: center, x: baseX)
            let side = Bool.random() ? center - 1 : center + 1
            let clampedSide = max(0, min(GameConfig.laneCount - 1, side))
            if clampedSide != center {
                spawn(kind: .lowBarrier, lane: clampedSide, x: baseX + 30)
            }

        case .e:
            // Train in one lane — the player has to stay out of it.
            let lane = Int.random(in: 0..<GameConfig.laneCount)
            spawn(kind: .train, lane: lane, x: baseX + GameConfig.trainLength / 2)
        }
    }

    private func spawn(kind: ObstacleKind, lane: Int, x: CGFloat) {
        guard let scene else { return }
        let laneY = laneConfig.yForLane(lane)
        let node = ObstacleNode(color: colorFor(kind: kind),
                                size: sizeFor(kind: kind))
        node.kind = kind
        node.lane = lane
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = 30

        let size = node.size
        let y: CGFloat
        switch kind {
        case .lowBarrier:
            y = laneY - GameConfig.playerHeight / 2 + size.height / 2
        case .tallBarrier:
            y = laneY + GameConfig.playerHeight / 2 - size.height / 2
        case .fullBlock, .train:
            y = laneY
        }

        node.position = CGPoint(x: x, y: y)
        scene.addChild(node)
        active.append(node)
    }

    private func colorFor(kind: ObstacleKind) -> SKColor {
        switch kind {
        case .lowBarrier, .tallBarrier: return .systemRed
        case .fullBlock, .train:        return SKColor(white: 0.25, alpha: 1)
        }
    }

    private func sizeFor(kind: ObstacleKind) -> CGSize {
        switch kind {
        case .lowBarrier:
            return CGSize(width: GameConfig.obstacleWidth,
                          height: GameConfig.lowBarrierHeight)
        case .tallBarrier:
            return CGSize(width: GameConfig.obstacleWidth,
                          height: GameConfig.tallBarrierHeight)
        case .fullBlock:
            return CGSize(width: GameConfig.obstacleWidth,
                          height: GameConfig.fullBlockHeight)
        case .train:
            return CGSize(width: GameConfig.trainLength,
                          height: GameConfig.fullBlockHeight)
        }
    }

    // MARK: - Hitboxes

    var hitboxes: [CGRect] {
        active.map { o in
            CGRect(x: o.position.x - o.size.width / 2,
                   y: o.position.y - o.size.height / 2,
                   width: o.size.width,
                   height: o.size.height)
        }
    }
}
