import SpriteKit
import AppKit

/// Free Play mode: colorful letters on key press, shapes on click,
/// cursor follower with rainbow trail. The core toddler experience.
final class FreePlayMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }
    private var cursorFollower: SKShapeNode?
    private var trailEmitter: SKEmitterNode?
    private let soundManager = SoundManager.shared

    /// Infant / Toddler / Lively knobs, fixed for the life of the mode.
    private let style = PlayStyle.current

    /// Bright colors that look great on a dark background
    private let colors: [NSColor] = [
        .systemRed, .systemOrange, .systemYellow, .systemGreen,
        .systemBlue, .systemPurple, .systemPink, .systemTeal,
        .cyan, .magenta,
    ]

    /// Colors after the play style is applied (white on black for Infant).
    private lazy var palette: [NSColor] = style.palette(colors)

    /// Fun rounded fonts
    private let fontNames = ["Futura-Bold", "AvenirNext-Bold", "Helvetica-Bold"]

    init(size: CGSize) {
        let s = SKScene(size: size)
        s.backgroundColor = style.background(.black)
        s.scaleMode = .resizeFill
        self.scene = s

        setupCursorFollower()
    }

    // MARK: - PlayMode

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        let charSet = SettingsStore.shared.characterSet
        let displayChar = charSet.randomCharacter()
        spawnLetter(displayChar)

        // Lively spawns a few extra shapes on top of the letter.
        if style.spawnMultiplier > 1 {
            for _ in 1..<style.spawnMultiplier {
                spawnShape(at: randomPosition())
            }
        }

        soundManager.playKeyTone(keyCode: keyCode)
    }

    func handleKeyUp(keyCode: UInt16) {
        // No action on key up in free play
    }

    func handleMouseMove(position: CGPoint) {
        // Convert from screen coordinates (origin bottom-left) to scene coordinates
        let scenePos = CGPoint(x: position.x, y: position.y)
        cursorFollower?.position = scenePos
    }

    func handleMouseDown(position: CGPoint) {
        let scenePos = CGPoint(x: position.x, y: position.y)
        for _ in 0..<style.spawnMultiplier {
            spawnShape(at: scenePos)
        }
        spawnParticleBurst(at: scenePos)
        soundManager.playPop()
    }

    func handleMouseDragged(position: CGPoint) {
        handleMouseMove(position: position)
    }

    // MARK: - Letter Spawning

    private func spawnLetter(_ text: String) {
        let label = SKLabelNode(text: text)
        label.fontName = fontNames.randomElement()!
        label.fontSize = CGFloat.random(in: 80...160) * style.sizeScale
        label.fontColor = palette.randomElement()!
        label.position = randomPosition()
        label.setScale(0)
        label.zPosition = 10

        // Add glow effect. Infant style stays crisp: no blur.
        let glow = SKEffectNode()
        if !style.highContrast {
            glow.shouldRasterize = true
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10.0])
            let glowLabel = label.copy() as! SKLabelNode
            glowLabel.fontColor = label.fontColor?.withAlphaComponent(0.5)
            glow.addChild(glowLabel)
        }
        glow.zPosition = 9
        glow.position = label.position
        glow.setScale(0)
        scene.addChild(glow)

        scene.addChild(label)

        // Bouncy entrance
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.12)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        let entrance = SKAction.sequence([scaleUp, scaleDown])

        // Gentle float and fade
        let wait = SKAction.wait(forDuration: style.duration(1.5))
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -30...30), y: 80, duration: style.duration(1.0))
        let fadeOut = SKAction.fadeOut(withDuration: style.duration(1.0))
        let exit = SKAction.group([floatUp, fadeOut])
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([entrance, wait, exit, remove]))
        glow.run(SKAction.sequence([entrance, wait, exit, remove]))

        // Sparkle burst at letter position
        spawnSparkle(at: label.position, color: label.fontColor ?? .white)
    }

    // MARK: - Shape Spawning

    private func spawnShape(at position: CGPoint) {
        let color = palette.randomElement()!
        let shape: SKShapeNode

        let shapeType = Int.random(in: 0...3)
        let size = CGFloat.random(in: 30...70) * style.sizeScale

        switch shapeType {
        case 0: // Circle
            shape = SKShapeNode(circleOfRadius: size)
        case 1: // Star
            shape = SKShapeNode(path: starPath(points: 5, outerRadius: size, innerRadius: size * 0.4))
        case 2: // Heart
            shape = SKShapeNode(path: heartPath(size: size))
        default: // Triangle
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: -size * 0.866, y: -size * 0.5))
            path.addLine(to: CGPoint(x: size * 0.866, y: -size * 0.5))
            path.closeSubpath()
            shape = SKShapeNode(path: path)
        }

        shape.fillColor = color
        shape.strokeColor = .clear
        shape.position = position
        shape.setScale(0)
        shape.zPosition = 10

        // Add physics for tumbling
        shape.physicsBody = SKPhysicsBody(circleOfRadius: size * 0.5)
        shape.physicsBody?.affectedByGravity = true
        shape.physicsBody?.linearDamping = 0.5
        shape.physicsBody?.angularDamping = 0.3
        shape.physicsBody?.restitution = 0.6
        shape.physicsBody?.categoryBitMask = 0x1
        shape.physicsBody?.collisionBitMask = 0 // Don't collide with other shapes

        // Apply a random impulse
        let impulse = CGVector(
            dx: CGFloat.random(in: -200...200) * style.speedScale,
            dy: CGFloat.random(in: 100...400) * style.speedScale
        )

        scene.addChild(shape)

        let scaleIn = SKAction.scale(to: 1.0, duration: 0.15)
        let applyImpulse = SKAction.run { [style] in
            shape.physicsBody?.applyImpulse(impulse)
            shape.physicsBody?.applyAngularImpulse(CGFloat.random(in: -5...5) * style.speedScale)
        }
        let wait = SKAction.wait(forDuration: style.duration(3.0))
        let fadeOut = SKAction.fadeOut(withDuration: style.duration(1.0))
        let remove = SKAction.removeFromParent()

        shape.run(SKAction.sequence([scaleIn, applyImpulse, wait, fadeOut, remove]))
    }

    // MARK: - Particle Effects

    private func spawnSparkle(at position: CGPoint, color: NSColor) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = style.count(30)
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 80
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.3
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.position = position
        emitter.zPosition = 20

        // Use a small white circle texture
        emitter.particleTexture = createCircleTexture(radius: 8)

        scene.addChild(emitter)

        // Remove after particles finish
        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }

    private func spawnParticleBurst(at position: CGPoint) {
        let color = palette.randomElement()!
        spawnSparkle(at: position, color: color)
    }

    // MARK: - Cursor Follower

    private func setupCursorFollower() {
        let follower = SKShapeNode(circleOfRadius: 20 * style.sizeScale)
        follower.fillColor = style.highContrast ? .white : .systemYellow
        follower.strokeColor = .white
        follower.lineWidth = 2
        follower.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        follower.zPosition = 100
        follower.name = "cursorFollower"

        // Gentle pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: style.duration(0.5)),
            SKAction.scale(to: 1.0, duration: style.duration(0.5)),
        ])
        follower.run(SKAction.repeatForever(pulse))

        // Rainbow color cycling. Infant stays a fixed white/gray, no cycling.
        if !style.highContrast {
            let colorCycle = SKAction.sequence(palette.map { color in
                SKAction.sequence([
                    SKAction.run { follower.fillColor = color },
                    SKAction.wait(forDuration: 0.3),
                ])
            })
            follower.run(SKAction.repeatForever(colorCycle))
        }

        cursorFollower = follower
        scene.addChild(follower)

        // Trail emitter attached to follower
        let trail = SKEmitterNode()
        trail.particleBirthRate = 60
        trail.particleLifetime = 0.4
        trail.particleLifetimeRange = 0.1
        trail.particleSpeed = 0
        trail.particleScale = 0.2
        trail.particleScaleRange = 0.1
        trail.particleScaleSpeed = -0.3
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -2.0
        trail.particleColorBlendFactor = 1.0
        trail.particleBlendMode = .add
        trail.particleTexture = createCircleTexture(radius: 6)
        trail.particleColorSequence = style.highContrast
            ? SKKeyframeSequence(keyframeValues: [NSColor.white, NSColor.lightGray], times: [0, 1.0])
            : SKKeyframeSequence(
                keyframeValues: [NSColor.red, .orange, .yellow, .green, .cyan, .blue, .purple],
                times: [0, 0.15, 0.3, 0.45, 0.6, 0.75, 1.0]
            )
        trail.targetNode = scene // Particles stay in world space, not follower space
        trail.zPosition = 99

        follower.addChild(trail)
        trailEmitter = trail
    }

    // MARK: - Helpers

    private func randomPosition() -> CGPoint {
        let margin: CGFloat = 100
        return CGPoint(
            x: CGFloat.random(in: margin...(scene.size.width - margin)),
            y: CGFloat.random(in: margin...(scene.size.height - margin))
        )
    }

    private func createCircleTexture(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath(ovalIn: rect)
            NSColor.white.setFill()
            path.fill()
            return true
        }
        return SKTexture(image: image)
    }

    private func starPath(points: Int, outerRadius: CGFloat, innerRadius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let angleIncrement = .pi * 2 / CGFloat(points)

        for i in 0..<points {
            let outerAngle = CGFloat(i) * angleIncrement - .pi / 2
            let innerAngle = outerAngle + angleIncrement / 2

            let outerPoint = CGPoint(x: cos(outerAngle) * outerRadius, y: sin(outerAngle) * outerRadius)
            let innerPoint = CGPoint(x: cos(innerAngle) * innerRadius, y: sin(innerAngle) * innerRadius)

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        path.closeSubpath()
        return path
    }

    private func heartPath(size: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let s = size * 0.5

        path.move(to: CGPoint(x: 0, y: -s * 0.8))
        path.addCurve(
            to: CGPoint(x: 0, y: s),
            control1: CGPoint(x: -s * 2, y: -s * 0.2),
            control2: CGPoint(x: -s * 0.6, y: s * 1.2)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -s * 0.8),
            control1: CGPoint(x: s * 0.6, y: s * 1.2),
            control2: CGPoint(x: s * 2, y: -s * 0.2)
        )
        path.closeSubpath()
        return path
    }
}
