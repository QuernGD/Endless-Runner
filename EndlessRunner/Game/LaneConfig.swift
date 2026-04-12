import CoreGraphics
import Foundation

/// Helper that calculates lane Y positions based on scene size.
/// Side view: 3 horizontal bands stacked vertically above the ground.
struct LaneConfig {
    let sceneSize: CGSize
    let laneYPositions: [CGFloat]
    let groundTopY: CGFloat

    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        let groundTop = GameConfig.groundHeight
        self.groundTopY = groundTop

        // Playable area above the ground. Leave a little headroom for jumps.
        let topPadding: CGFloat = GameConfig.jumpHeight + 40
        let usable = sceneSize.height - groundTop - topPadding
        let bandHeight = usable / CGFloat(GameConfig.laneCount)

        var positions: [CGFloat] = []
        for i in 0..<GameConfig.laneCount {
            // Lane 0 = bottom, Lane 2 = top
            let centerY = groundTop + bandHeight * (CGFloat(i) + 0.5)
            positions.append(centerY)
        }
        self.laneYPositions = positions
    }

    func yForLane(_ lane: Int) -> CGFloat {
        let clamped = max(0, min(GameConfig.laneCount - 1, lane))
        return laneYPositions[clamped]
    }

    var playerX: CGFloat {
        sceneSize.width * GameConfig.playerXFraction
    }
}
