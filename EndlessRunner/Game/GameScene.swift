import SpriteKit

protocol GameSceneDelegate: AnyObject {
    func gameSceneDidEnd(score: Int, distance: Int, coins: Int, highScore: Int)
}

final class GameScene: SKScene {
    weak var gameDelegate: GameSceneDelegate?

    private var laneConfig: LaneConfig = LaneConfig(sceneSize: CGSize(width: 390, height: 844))
    private var player: Player?
    private var obstacles: ObstacleManager?
    private var coins: CoinManager?
    private let scoreManager = ScoreManager()

    private var scrollSpeed: CGFloat = GameConfig.baseScrollSpeed
    private var elapsed: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var lastSpeedBump: TimeInterval = 0
    private var gameOver = false

    // HUD
    private var scoreLabel: SKLabelNode?
    private var coinsLabel: SKLabelNode?

    // Ground / scrolling lane dividers
    private var groundNode: SKSpriteNode?
    private var dividerContainer: SKNode?

    // Touch tracking for swipe detection.
    private var touchStart: CGPoint?
    private var touchStartTime: TimeInterval = 0

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.62, green: 0.84, blue: 0.97, alpha: 1)
        rebuildScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 0, size.height > 0 else { return }
        if !children.isEmpty {
            rebuildScene()
        }
    }

    private func rebuildScene() {
        removeAllChildren()
        removeAllActions()

        laneConfig = LaneConfig(sceneSize: size)
        scoreManager.reset()
        scrollSpeed = GameConfig.baseScrollSpeed
        elapsed = 0
        lastUpdate = 0
        lastSpeedBump = 0
        gameOver = false

        setupBackground()
        setupGround()
        setupHUD()

        let p = Player(laneConfig: laneConfig)
        addChild(p)
        self.player = p

        let om = ObstacleManager(scene: self, laneConfig: laneConfig)
        self.obstacles = om
        let cm = CoinManager(scene: self, laneConfig: laneConfig)
        self.coins = cm
    }

    private func setupBackground() {
        // Solid color already set; add sun-like circle for flavor.
        let sun = SKShapeNode(circleOfRadius: 30)
        sun.fillColor = SKColor(red: 1, green: 0.95, blue: 0.7, alpha: 1)
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 60, y: size.height - 80)
        sun.zPosition = 1
        addChild(sun)
    }

    private func setupGround() {
        let ground = SKSpriteNode(color: SKColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1),
                                  size: CGSize(width: size.width, height: GameConfig.groundHeight))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = CGPoint(x: 0, y: 0)
        ground.zPosition = 5
        addChild(ground)
        self.groundNode = ground

        // Lane dividers between lanes scroll left and loop. We draw them on a
        // container that spans 2x width so we can shift it in place.
        let container = SKNode()
        container.zPosition = 10
        addChild(container)
        self.dividerContainer = container

        drawDividers(on: container)
    }

    private func drawDividers(on container: SKNode) {
        container.removeAllChildren()
        let lanes = laneConfig.laneYPositions
        // Divider lines: between lanes. For 3 lanes we draw 2 divider lines,
        // plus a line at ground top.
        var dividerYs: [CGFloat] = [laneConfig.groundTopY]
        for i in 0..<(lanes.count - 1) {
            let y = (lanes[i] + lanes[i + 1]) / 2
            dividerYs.append(y)
        }

        let dashWidth: CGFloat = 30
        let gapWidth: CGFloat = 20
        let segment = dashWidth + gapWidth
        let totalWidth = size.width + segment
        let count = Int(totalWidth / segment) + 2

        for y in dividerYs {
            for i in 0..<count {
                let dash = SKSpriteNode(color: .white,
                                        size: CGSize(width: dashWidth, height: 2))
                dash.anchorPoint = CGPoint(x: 0, y: 0.5)
                dash.position = CGPoint(x: CGFloat(i) * segment, y: y)
                container.addChild(dash)
            }
        }
    }

    private func setupHUD() {
        let score = SKLabelNode(fontNamed: "AvenirNext-Bold")
        score.text = "0"
        score.fontSize = 28
        score.fontColor = .white
        score.horizontalAlignmentMode = .center
        score.position = CGPoint(x: size.width / 2, y: size.height - 60)
        score.zPosition = 100
        addChild(score)
        self.scoreLabel = score

        let c = SKLabelNode(fontNamed: "AvenirNext-Bold")
        c.text = "Coins: 0"
        c.fontSize = 20
        c.fontColor = .yellow
        c.horizontalAlignmentMode = .left
        c.position = CGPoint(x: 16, y: size.height - 60)
        c.zPosition = 100
        addChild(c)
        self.coinsLabel = c
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 {
            lastUpdate = currentTime
            lastSpeedBump = currentTime
            return
        }
        let dtRaw = currentTime - lastUpdate
        lastUpdate = currentTime
        let dt = CGFloat(min(dtRaw, 1.0 / 30.0))

        guard !gameOver else { return }
        elapsed += dtRaw

        // Speed bumps.
        if currentTime - lastSpeedBump >= GameConfig.speedIncreaseInterval {
            lastSpeedBump = currentTime
            scrollSpeed = min(GameConfig.maxScrollSpeed,
                              scrollSpeed * GameConfig.speedIncreaseRate)
        }

        // Scroll lane dividers.
        if let container = dividerContainer {
            let segment: CGFloat = 50 // dash 30 + gap 20
            container.position.x -= scrollSpeed * dt
            if container.position.x <= -segment {
                container.position.x += segment
            }
        }

        obstacles?.update(dt: dt, scrollSpeed: scrollSpeed)
        coins?.update(dt: dt, scrollSpeed: scrollSpeed)

        // Distance scoring: points scale with speed.
        scoreManager.addDistance(scrollSpeed * dt / 10)

        if let player, let coins {
            let collected = coins.collectOverlapping(player: player.hitbox)
            for _ in 0..<collected {
                scoreManager.collectCoin()
            }
        }

        // Collision.
        if let player, player.state != .dead, let obstacles {
            let pbox = player.hitbox
            for obox in obstacles.hitboxes {
                if pbox.intersects(obox) {
                    triggerGameOver()
                    break
                }
            }
        }

        scoreLabel?.text = "\(scoreManager.score)"
        coinsLabel?.text = "Coins: \(scoreManager.coins)"
    }

    private func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true
        player?.die()
        let dark = SKSpriteNode(color: SKColor(white: 0, alpha: 0.35),
                                size: size)
        dark.anchorPoint = .zero
        dark.zPosition = 90
        dark.alpha = 0
        addChild(dark)
        dark.run(SKAction.fadeAlpha(to: 1, duration: 0.3))

        scoreManager.commitHighScores()
        let distanceInt = Int(scoreManager.distance)
        let coinsInt = scoreManager.coins
        let scoreInt = scoreManager.score
        let highInt = scoreManager.highScore
        let delegate = gameDelegate
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run {
                delegate?.gameSceneDidEnd(score: scoreInt,
                                          distance: distanceInt,
                                          coins: coinsInt,
                                          highScore: highInt)
            }
        ]))
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let t = touches.first else { return }
        touchStart = t.location(in: self)
        touchStartTime = t.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let t = touches.first, let start = touchStart else { return }
        touchStart = nil
        let end = t.location(in: self)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let absX = abs(dx)
        let absY = abs(dy)
        let threshold = GameConfig.swipeThreshold

        if absX < threshold && absY < threshold {
            // Treat as a tap — default to jump.
            player?.jump()
            return
        }

        if absX > absY {
            // Horizontal swipe.
            if dx > 0 {
                player?.switchLane(direction: 1)
            } else {
                player?.switchLane(direction: -1)
            }
        } else {
            // Vertical swipe. In SpriteKit default coordinates y+ is up.
            if dy > 0 {
                player?.jump()
            } else {
                player?.slide()
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = nil
    }
}
