import SpriteKit

/// The player avatar. A blue rectangle that runs, jumps, slides and switches lanes.
final class Player: SKSpriteNode {
    enum State {
        case running
        case jumping
        case sliding
        case dead
    }

    private(set) var state: State = .running
    private(set) var currentLane: Int = 1

    private var laneConfig: LaneConfig

    // Logical size base values.
    private let baseSize = CGSize(width: GameConfig.playerWidth,
                                  height: GameConfig.playerHeight)

    init(laneConfig: LaneConfig) {
        self.laneConfig = laneConfig
        super.init(texture: nil,
                   color: .systemBlue,
                   size: CGSize(width: GameConfig.playerWidth,
                                height: GameConfig.playerHeight))
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.zPosition = 50
        self.position = CGPoint(x: laneConfig.playerX,
                                y: laneConfig.yForLane(currentLane))
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    // MARK: - Config updates

    func updateLaneConfig(_ config: LaneConfig) {
        self.laneConfig = config
        self.position.x = config.playerX
        if state == .running {
            self.position.y = config.yForLane(currentLane)
        }
    }

    // MARK: - Lane switching

    func switchLane(direction: Int) {
        let target = max(0, min(GameConfig.laneCount - 1, currentLane + direction))
        guard target != currentLane else { return }
        currentLane = target
        // For jumping, the custom action recomputes y from the current lane
        // every frame, so we only need to tween y when running or sliding.
        if state == .jumping { return }

        let targetY: CGFloat
        if state == .sliding {
            // Keep the slide vertical offset (-delta).
            let delta = (baseSize.height - GameConfig.playerSlideHeight) / 2
            targetY = laneConfig.yForLane(target) - delta
        } else {
            targetY = laneConfig.yForLane(target)
        }
        let move = SKAction.moveTo(y: targetY,
                                   duration: GameConfig.laneSwitchDuration)
        move.timingMode = .easeInEaseOut
        removeAction(forKey: "laneSwitch")
        run(move, withKey: "laneSwitch")
    }

    // MARK: - Jump

    func jump() {
        guard state == .running else { return }
        state = .jumping
        removeAction(forKey: "laneSwitch")

        let total = GameConfig.jumpDuration
        let jumpAction = SKAction.customAction(withDuration: total) { [weak self] node, elapsed in
            guard let self else { return }
            let t = min(1, max(0, CGFloat(elapsed) / CGFloat(total)))
            // Parabola: 4 * t * (1 - t) gives 0 → 1 → 0
            let arc = 4 * t * (1 - t) * GameConfig.jumpHeight
            node.position.y = self.laneConfig.yForLane(self.currentLane) + arc
        }
        let finish = SKAction.run { [weak self] in
            guard let self else { return }
            if self.state == .jumping {
                self.state = .running
                self.position.y = self.laneConfig.yForLane(self.currentLane)
            }
        }
        removeAction(forKey: "jump")
        run(SKAction.sequence([jumpAction, finish]), withKey: "jump")
    }

    // MARK: - Slide

    func slide() {
        guard state == .running else { return }
        state = .sliding

        let shrunken = CGSize(width: baseSize.width,
                              height: GameConfig.playerSlideHeight)
        let delta = (baseSize.height - shrunken.height) / 2
        self.size = shrunken
        self.position.y = laneConfig.yForLane(currentLane) - delta

        let wait = SKAction.wait(forDuration: GameConfig.slideDuration)
        let restore = SKAction.run { [weak self] in
            guard let self else { return }
            self.size = self.baseSize
            self.position.y = self.laneConfig.yForLane(self.currentLane)
            self.state = .running
        }
        removeAction(forKey: "slide")
        run(SKAction.sequence([wait, restore]), withKey: "slide")
    }

    // MARK: - Death

    func die() {
        state = .dead
        removeAction(forKey: "jump")
        removeAction(forKey: "slide")
        removeAction(forKey: "laneSwitch")
        let tilt = SKAction.rotate(toAngle: -.pi / 4, duration: 0.2)
        let fade = SKAction.fadeAlpha(to: 0.5, duration: 0.2)
        run(SKAction.group([tilt, fade]))
    }

    // MARK: - Collision

    /// Axis-aligned bounding box in scene coordinates.
    var hitbox: CGRect {
        let pad: CGFloat = 2
        return CGRect(x: position.x - size.width / 2 + pad,
                      y: position.y - size.height / 2 + pad,
                      width: size.width - pad * 2,
                      height: size.height - pad * 2)
    }
}
