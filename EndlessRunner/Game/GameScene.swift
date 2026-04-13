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
    private var lastUpdate: TimeInterval = 0
    private var lastSpeedBump: TimeInterval = 0
    private var gameOver = false
    private var cameraNode: SKCameraNode?

    // HUD
    private var distanceLabel: SKLabelNode?
    private var coinsLabel: SKLabelNode?

    // Layers
    private var skyLayer: SKNode?
    private var midLayer: SKNode?
    private var dividerContainer: SKNode?

    // Touch tracking for swipe detection.
    private var touchStart: CGPoint?

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
        lastUpdate = 0
        lastSpeedBump = 0
        gameOver = false

        // Camera lets us shake the view cleanly on death.
        let cam = SKCameraNode()
        cam.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cam)
        self.camera = cam
        self.cameraNode = cam

        setupSky()
        setupMidground()
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

    // MARK: - Setup

    private func setupSky() {
        let sky = SKNode()
        sky.zPosition = 0
        addChild(sky)
        self.skyLayer = sky

        // Sun disc.
        let sun = SKShapeNode(circleOfRadius: 34)
        sun.fillColor = SKColor(red: 1, green: 0.95, blue: 0.7, alpha: 1)
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 70, y: size.height - 100)
        sun.zPosition = 1
        sky.addChild(sun)

        // A few drifting cloud rectangles.
        for _ in 0..<5 {
            let w = CGFloat.random(in: 50...110)
            let h = CGFloat.random(in: 14...22)
            let cloud = SKSpriteNode(color: SKColor(white: 1, alpha: 0.85),
                                     size: CGSize(width: w, height: h))
            cloud.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: (size.height * 0.55)...(size.height - 120))
            )
            cloud.zPosition = 2
            sky.addChild(cloud)
        }
    }

    private func setupMidground() {
        let mid = SKNode()
        mid.zPosition = 3
        addChild(mid)
        self.midLayer = mid

        // Spawn buildings across roughly 2x the screen width so we always have
        // something to scroll in.
        let skyline = GameConfig.groundHeight
        var x: CGFloat = 0
        while x < size.width * 2 {
            let w = CGFloat.random(in: 40...90)
            let h = CGFloat.random(in: 60...160)
            let color = randomBuildingColor()
            let node = SKSpriteNode(color: color, size: CGSize(width: w, height: h))
            node.anchorPoint = CGPoint(x: 0, y: 0)
            node.position = CGPoint(x: x, y: skyline)
            node.zPosition = 3
            mid.addChild(node)

            // Optional colored window row.
            let windowCount = Int(h / 24)
            for i in 0..<windowCount {
                let win = SKSpriteNode(color: SKColor(white: 1, alpha: 0.55),
                                       size: CGSize(width: w * 0.35, height: 6))
                win.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                win.position = CGPoint(x: w / 2, y: 14 + CGFloat(i) * 24)
                node.addChild(win)
            }

            x += w + CGFloat.random(in: 8...30)
        }
    }

    private func randomBuildingColor() -> SKColor {
        let palette: [SKColor] = [
            SKColor(red: 0.38, green: 0.45, blue: 0.60, alpha: 1),
            SKColor(red: 0.52, green: 0.58, blue: 0.70, alpha: 1),
            SKColor(red: 0.44, green: 0.52, blue: 0.66, alpha: 1),
            SKColor(red: 0.30, green: 0.38, blue: 0.52, alpha: 1),
        ]
        return palette[Int.random(in: 0..<palette.count)]
    }

    private func setupGround() {
        let ground = SKSpriteNode(color: SKColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1),
                                  size: CGSize(width: size.width, height: GameConfig.groundHeight))
        ground.anchorPoint = CGPoint(x: 0, y: 0)
        ground.position = CGPoint(x: 0, y: 0)
        ground.zPosition = 5
        addChild(ground)

        let container = SKNode()
        container.zPosition = 10
        addChild(container)
        self.dividerContainer = container

        drawDividers(on: container)
    }

    private func drawDividers(on container: SKNode) {
        container.removeAllChildren()
        let lanes = laneConfig.laneYPositions
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
        let distance = SKLabelNode(fontNamed: "AvenirNext-Bold")
        distance.text = "0m"
        distance.fontSize = 34
        distance.fontColor = .white
        distance.horizontalAlignmentMode = .center
        distance.position = CGPoint(x: size.width / 2, y: size.height - 64)
        distance.zPosition = 100
        addChild(distance)
        self.distanceLabel = distance

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

        // Speed bumps.
        if currentTime - lastSpeedBump >= GameConfig.speedIncreaseInterval {
            lastSpeedBump = currentTime
            let newSpeed = min(GameConfig.maxScrollSpeed,
                               scrollSpeed * GameConfig.speedIncreaseRate)
            if newSpeed > scrollSpeed {
                scrollSpeed = newSpeed
                showSpeedUpToast()
            }
        }

        // Parallax scrolling.
        scrollParallax(dt: dt)

        // Scroll lane dividers (foreground).
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

        // Collision + near miss.
        if let player, player.state != .dead, let obstacles {
            let pbox = player.hitbox
            var didCollide = false
            for node in obstacles.active {
                let obox = CGRect(x: node.position.x - node.size.width / 2,
                                  y: node.position.y - node.size.height / 2,
                                  width: node.size.width,
                                  height: node.size.height)
                if pbox.intersects(obox) {
                    didCollide = true
                    break
                }
                // Near-miss: smallest edge-to-edge gap between the two
                // hitboxes is non-zero and within `nearMissDistance`.
                if !node.nearMissReported {
                    let gap = minGap(a: pbox, b: obox)
                    if gap > 0 && gap <= GameConfig.nearMissDistance {
                        node.nearMissReported = true
                        showNearMiss(at: player.position)
                    }
                }
            }
            if didCollide { triggerGameOver() }
        }

        distanceLabel?.text = "\(Int(scoreManager.distance / 10))m"
        coinsLabel?.text = "Coins: \(scoreManager.coins)"
    }

    private func scrollParallax(dt: CGFloat) {
        // Sky: static apart from very slow drift.
        skyLayer?.position.x -= scrollSpeed * 0.05 * dt
        if let sky = skyLayer, sky.position.x < -size.width {
            sky.position.x = 0
        }

        // Midground: 0.3x game speed with recycling buildings.
        let midDelta = scrollSpeed * 0.3 * dt
        guard let mid = midLayer else { return }
        // We can't mutate building layer positions via mid.position since we
        // need individual recycling. Instead we move each child.
        var maxRightEdge: CGFloat = 0
        for child in mid.children {
            child.position.x -= midDelta
            let rightEdge = child.position.x + child.frame.width
            if rightEdge > maxRightEdge { maxRightEdge = rightEdge }
        }
        for child in mid.children {
            if child.position.x + child.frame.width < -20 {
                let newW = CGFloat.random(in: 40...90)
                let newH = CGFloat.random(in: 60...160)
                if let sprite = child as? SKSpriteNode {
                    sprite.size = CGSize(width: newW, height: newH)
                    sprite.color = randomBuildingColor()
                    // Clear and redraw simple windows.
                    sprite.removeAllChildren()
                    let windowCount = Int(newH / 24)
                    for i in 0..<windowCount {
                        let win = SKSpriteNode(color: SKColor(white: 1, alpha: 0.55),
                                               size: CGSize(width: newW * 0.35, height: 6))
                        win.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                        win.position = CGPoint(x: newW / 2, y: 14 + CGFloat(i) * 24)
                        sprite.addChild(win)
                    }
                }
                child.position.x = maxRightEdge + CGFloat.random(in: 8...30)
                maxRightEdge = child.position.x + child.frame.width
            }
        }
    }

    // MARK: - Feedback

    private func showSpeedUpToast() {
        // Quick white flash over the whole scene.
        let flash = SKSpriteNode(color: .white, size: size)
        flash.anchorPoint = .zero
        flash.alpha = 0
        flash.zPosition = 200
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.45, duration: 0.08),
            SKAction.fadeAlpha(to: 0, duration: 0.25),
            SKAction.removeFromParent()
        ]))

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "SPEED UP!"
        label.fontSize = 36
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 201
        label.setScale(0.5)
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.2),
                SKAction.fadeIn(withDuration: 0.1)
            ]),
            SKAction.wait(forDuration: 0.5),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    /// Minimum edge-to-edge distance between two rects. Returns 0 when they
    /// intersect.
    private func minGap(a: CGRect, b: CGRect) -> CGFloat {
        let dx = max(0, max(b.minX - a.maxX, a.minX - b.maxX))
        let dy = max(0, max(b.minY - a.maxY, a.minY - b.maxY))
        return (dx * dx + dy * dy).squareRoot()
    }

    private func showNearMiss(at point: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "!"
        label.fontSize = 44
        label.fontColor = .yellow
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: point.x, y: point.y + 60)
        label.zPosition = 180
        label.setScale(0.2)
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.12),
                SKAction.fadeIn(withDuration: 0.08)
            ]),
            SKAction.wait(forDuration: 0.25),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 20, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Game over

    private func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true
        player?.die()

        // 0.3s hit-stop freeze then camera shake.
        let freeze = SKAction.wait(forDuration: 0.3)
        let shake = shakeAction(magnitude: GameConfig.deathShakeMagnitude,
                                duration: 0.35)

        // Dark overlay is pinned to the camera so it fills the viewport
        // regardless of camera shake.
        let dark = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55),
                                size: size)
        dark.anchorPoint = .zero
        dark.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        dark.zPosition = 90
        dark.alpha = 0
        cameraNode?.addChild(dark)
        let fade = SKAction.run {
            dark.run(SKAction.fadeAlpha(to: 1, duration: 0.35))
        }

        scoreManager.commitHighScores()
        let distanceInt = Int(scoreManager.distance / 10)
        let coinsInt = scoreManager.coins
        let scoreInt = scoreManager.score
        let highInt = scoreManager.highScore
        let delegate = gameDelegate

        run(SKAction.sequence([
            freeze,
            shake,
            fade,
            SKAction.wait(forDuration: 0.4),
            SKAction.run {
                delegate?.gameSceneDidEnd(score: scoreInt,
                                          distance: distanceInt,
                                          coins: coinsInt,
                                          highScore: highInt)
            }
        ]))
    }

    private func shakeAction(magnitude: CGFloat, duration: TimeInterval) -> SKAction {
        // Shake the camera rather than the scene so overlays attached to the
        // scene stay fixed relative to the viewport.
        guard let cam = cameraNode else {
            return SKAction.wait(forDuration: duration)
        }
        let origin = cam.position
        let stepCount = 10
        let stepDuration = duration / TimeInterval(stepCount)
        var actions: [SKAction] = []
        for i in 0..<stepCount {
            let falloff = 1 - CGFloat(i) / CGFloat(stepCount)
            let dx = CGFloat.random(in: -magnitude...magnitude) * falloff
            let dy = CGFloat.random(in: -magnitude...magnitude) * falloff
            actions.append(SKAction.move(
                to: CGPoint(x: origin.x + dx, y: origin.y + dy),
                duration: stepDuration))
        }
        actions.append(SKAction.move(to: origin, duration: stepDuration / 2))
        return SKAction.run { cam.run(SKAction.sequence(actions)) }
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let t = touches.first else { return }
        touchStart = t.location(in: self)
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

        // Dead zone → treat as tap → jump (accessibility).
        if absX < threshold && absY < threshold {
            player?.jump()
            return
        }

        // Horizontal takes priority if its delta is larger than vertical.
        if absX > absY {
            if dx > 0 {
                player?.switchLane(direction: 1)
            } else {
                player?.switchLane(direction: -1)
            }
        } else {
            // Vertical swipe. SpriteKit default coordinates: y+ is up.
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
