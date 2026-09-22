import SpriteKit

/// Chill mode — a low-stimulation experience for quieter play.
///
/// Design principles:
///   - Soft pastel background, no vibrant colors.
///   - Slow, floaty spawns of friendly objects: fruits, vegetables, animals.
///   - Key presses spawn one object at a time. Mouse movement does nothing flashy —
///     just a subtle soft glow that trails behind.
///   - No particle explosions, no rainbows, no rapid color cycling.
///   - Sound effects are quieter if enabled; background music still follows the user's setting.
///   - Infant style trades emoji for plain white shapes on black and adds a
///     gentle auto-spawn so the scene stays alive on its own.
final class ChillMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }
    private let soundManager = SoundManager.shared

    /// Infant / Toddler / Lively knobs, fixed for the life of the mode.
    private let style = PlayStyle.current

    // Friendly emoji set: fruits, vegetables, and calm animals.
    // Rendered via SKLabelNode so we don't need image assets.
    private let items: [String] = [
        // Fruits
        "🍎", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍒", "🍑", "🥭", "🍍", "🥝", "🍐", "🥥",
        // Vegetables
        "🥕", "🥒", "🌽", "🥔", "🍅", "🫑", "🥦", "🧅", "🧄", "🥬", "🍆",
        // Calm animals
        "🐢", "🐌", "🦉", "🦊", "🐰", "🐨", "🐼", "🐣", "🦋", "🐞", "🐝", "🐑", "🦢", "🐳", "🦔"
    ]

    /// Cap on concurrent floating items so the screen stays calm.
    private let maxConcurrentItems = 18

    /// Soft cursor glow that trails behind the mouse.
    private let cursorGlow: SKShapeNode

    init(size: CGSize) {
        let s = SKScene(size: size)
        s.scaleMode = .resizeFill
        // Soft mint-cream background — easy on the eyes. Infant swaps to black.
        s.backgroundColor = style.background(NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.92, alpha: 1.0))
        self.scene = s

        let glow = SKShapeNode(circleOfRadius: 40)
        glow.fillColor = style.highContrast
            ? NSColor(calibratedWhite: 1.0, alpha: 0.35)
            : NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.85, alpha: 0.55)
        glow.strokeColor = .clear
        glow.blendMode = .alpha
        glow.zPosition = 10
        glow.alpha = 0.0
        glow.position = CGPoint(x: size.width / 2, y: size.height / 2)
        self.cursorGlow = glow
        s.addChild(glow)

        // Add a very faint vignette of soft dots floating ambiently so the
        // scene isn't static when idle, without being stimulating.
        addAmbientDots()

        // The scene drifts on its own, so a toddler who only watches still
        // sees something. Keys and clicks add more on top of this.
        s.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: style.duration(3.5)),
            SKAction.run { [weak self] in self?.spawnFloatingItem() },
        ])))
        spawnFloatingItem()
    }

    // MARK: - Ambient background

    private func addAmbientDots() {
        for _ in 0..<6 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 30...60))
            dot.fillColor = NSColor(calibratedWhite: 1.0, alpha: style.highContrast ? 0.12 : 0.35)
            dot.strokeColor = .clear
            dot.position = CGPoint(
                x: CGFloat.random(in: 0...scene.size.width),
                y: CGFloat.random(in: 0...scene.size.height)
            )
            dot.zPosition = 0
            scene.addChild(dot)

            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -30...30),
                y: CGFloat.random(in: -30...30),
                duration: style.duration(TimeInterval.random(in: 8.0...14.0))
            )
            dot.run(SKAction.repeatForever(SKAction.sequence([drift, drift.reversed()])))
        }
    }

    // MARK: - Input handling

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        spawnFloatingItem()
        // Quiet tone — reuse soft keypress sound but softly.
        soundManager.playKeyTone(keyCode: keyCode)
    }

    func handleKeyUp(keyCode: UInt16) {}

    func handleMouseMove(position: CGPoint) {
        // Slide the glow toward the new position smoothly — no snappy movement.
        cursorGlow.removeAction(forKey: "follow")
        let follow = SKAction.move(to: position, duration: 0.45)
        follow.timingMode = .easeOut
        cursorGlow.run(follow, withKey: "follow")

        // Fade in on the first movement, stays visible while active.
        if cursorGlow.alpha < 0.1 {
            cursorGlow.run(SKAction.fadeAlpha(to: 0.6, duration: 0.6))
        }
        // Cancel any pending fade-out and schedule a new one.
        cursorGlow.removeAction(forKey: "idleFade")
        let idleFade = SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeAlpha(to: 0.0, duration: 1.2)
        ])
        cursorGlow.run(idleFade, withKey: "idleFade")
    }

    func handleMouseDown(position: CGPoint) {
        // Gentle ripple — one soft expanding ring, no color explosion.
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.strokeColor = style.highContrast
            ? NSColor(calibratedWhite: 1.0, alpha: 0.8)
            : NSColor(calibratedRed: 0.85, green: 0.78, blue: 0.95, alpha: 0.7)
        ring.lineWidth = 4
        ring.fillColor = .clear
        ring.position = position
        ring.zPosition = 5
        scene.addChild(ring)

        let expand = SKAction.scale(to: 4.0, duration: style.duration(1.2))
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: style.duration(1.2))
        ring.run(SKAction.group([expand, fade])) { [weak ring] in
            ring?.removeFromParent()
        }

        // Spawn an item where the user clicked.
        spawnFloatingItem(at: position)
    }

    func handleMouseDragged(position: CGPoint) {
        handleMouseMove(position: position)
    }

    // MARK: - Floating items

    private func spawnFloatingItem(at overridePosition: CGPoint? = nil) {
        // Cap concurrent items so the scene stays calm.
        let itemCount = scene.children.filter { $0.name == "chillItem" }.count
        if itemCount >= maxConcurrentItems {
            // Remove the oldest one gently to make room.
            if let oldest = scene.children.first(where: { $0.name == "chillItem" }) {
                oldest.run(SKAction.fadeOut(withDuration: 0.6)) { [weak oldest] in
                    oldest?.removeFromParent()
                }
            }
        }

        let label = makeItemNode()
        label.name = "chillItem"
        label.zPosition = 3
        label.alpha = 0.0

        let startX: CGFloat
        let startY: CGFloat
        if let p = overridePosition {
            startX = p.x
            startY = p.y
        } else {
            startX = CGFloat.random(in: 80...(scene.size.width - 80))
            startY = CGFloat.random(in: 80...(scene.size.height - 80))
        }
        label.position = CGPoint(x: startX, y: startY)
        scene.addChild(label)

        // Very slow gentle drift, slight rotation, long fade-in and fade-out.
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: style.duration(1.4))
        let drift = SKAction.moveBy(
            x: CGFloat.random(in: -120...120),
            y: CGFloat.random(in: 60...180),
            duration: style.duration(TimeInterval.random(in: 10.0...16.0))
        )
        drift.timingMode = .easeInEaseOut
        let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -0.6...0.6), duration: drift.duration)
        let fadeOut = SKAction.fadeOut(withDuration: style.duration(2.0))
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([
            fadeIn,
            SKAction.group([drift, rotate]),
            fadeOut,
            remove
        ]))
    }

    /// An emoji for the normal styles; a plain white shape for Infant,
    /// since emoji cannot be high-contrast.
    private func makeItemNode() -> SKNode {
        let itemSize = CGFloat.random(in: 70...110) * style.sizeScale

        guard style.highContrast else {
            let symbol = items.randomElement() ?? "🍎"
            let label = SKLabelNode(text: symbol)
            label.fontSize = itemSize
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            return label
        }

        let radius = itemSize * 0.4
        let shape: SKShapeNode
        switch Int.random(in: 0...3) {
        case 0:
            shape = SKShapeNode(circleOfRadius: radius)
            shape.fillColor = .white
        case 1:
            shape = SKShapeNode(circleOfRadius: radius)
            shape.fillColor = .clear
            shape.lineWidth = radius * 0.3
        case 2:
            shape = SKShapeNode(rectOf: CGSize(width: radius * 1.7, height: radius * 1.7), cornerRadius: radius * 0.3)
            shape.fillColor = .white
        default:
            shape = SKShapeNode(path: starPath(points: 5, outerRadius: radius, innerRadius: radius * 0.45))
            shape.fillColor = .white
        }
        shape.strokeColor = .white
        return shape
    }

    private func starPath(points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angleIncrement = .pi * 2 / CGFloat(points)
        for i in 0..<points {
            let outerAngle = CGFloat(i) * angleIncrement - .pi / 2
            let innerAngle = outerAngle + angleIncrement / 2
            let outerPoint = CGPoint(x: cos(outerAngle) * outerRadius, y: sin(outerAngle) * outerRadius)
            let innerPoint = CGPoint(x: cos(innerAngle) * innerRadius, y: sin(innerAngle) * innerRadius)
            if i == 0 { path.move(to: outerPoint) } else { path.addLine(to: outerPoint) }
            path.addLine(to: innerPoint)
        }
        path.closeSubpath()
        return path
    }
}
