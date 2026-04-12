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
}

/// Spawns and manages obstacles. Tracks active nodes for manual collision.
final class ObstacleManager {
    private weak var scene: SKScene?
    private(set) var active: [ObstacleNode] = []
    private var laneConfig: LaneConfig
    private var distanceSinceLastSpawn: CGFloat = 0
    private var nextSpawnGap: CGFloat = GameConfig.minObstacleSpacing

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
        nextSpawnGap = GameConfig.minObstacleSpacing
    }

    // MARK: - Update

    func update(dt: CGFloat, scrollSpeed: CGFloat) {
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
            // Slightly randomize spacing so patterns feel less metronomic.
            let jitter = CGFloat.random(in: 0...80)
            nextSpawnGap = GameConfig.minObstacleSpacing + jitter
            spawnGroup()
        }
    }

    // MARK: - Spawning

    private func spawnGroup() {
        guard let scene else { return }
        let allLanes = Array(0..<GameConfig.laneCount)

        // Decide how many lanes to block. Never block all 3.
        let blockCount = Int.random(in: 1...2)
        let shuffled = allLanes.shuffled()
        let blockedLanes = Array(shuffled.prefix(blockCount))

        // Spawn X at right edge, with slight per-obstacle jitter inside a group.
        let baseX = scene.size.width + GameConfig.obstacleWidth

        for (i, lane) in blockedLanes.enumerated() {
            let kind = randomKindFor(lane: lane, blockCount: blockCount)
            let xJitter: CGFloat = CGFloat(i) * 10
            spawn(kind: kind, lane: lane, x: baseX + xJitter)
        }
    }

    private func randomKindFor(lane: Int, blockCount: Int) -> ObstacleKind {
        // If we're already blocking 2 lanes, keep this one easy (don't stack trains).
        if blockCount == 2 {
            let r = Int.random(in: 0..<3)
            switch r {
            case 0: return .lowBarrier
            case 1: return .tallBarrier
            default: return .fullBlock
            }
        } else {
            let r = Int.random(in: 0..<4)
            switch r {
            case 0: return .lowBarrier
            case 1: return .tallBarrier
            case 2: return .fullBlock
            default: return .train
            }
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
            // Sits at the bottom of the lane band.
            y = laneY - GameConfig.playerHeight / 2 + size.height / 2
        case .tallBarrier:
            // Hangs from the top of the lane band so the player must slide.
            y = laneY + GameConfig.playerHeight / 2 - size.height / 2
        case .fullBlock:
            y = laneY
        case .train:
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
