import AppKit
import SpriteKit

/// A restrained ten-note celesta. The visual response is the instrument
/// itself, not unrelated particles or shapes.
final class MusicMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }

    private var bars: [SKShapeNode] = []
    private let colors: [NSColor] = [
        StorybookPalette.clay,
        NSColor(calibratedRed: 0.82, green: 0.53, blue: 0.30, alpha: 1),
        StorybookPalette.mustard,
        StorybookPalette.sage,
        NSColor(calibratedRed: 0.30, green: 0.59, blue: 0.61, alpha: 1),
        NSColor(calibratedRed: 0.34, green: 0.48, blue: 0.66, alpha: 1),
        NSColor(calibratedRed: 0.48, green: 0.42, blue: 0.64, alpha: 1),
        NSColor(calibratedRed: 0.67, green: 0.43, blue: 0.58, alpha: 1),
        NSColor(calibratedRed: 0.72, green: 0.48, blue: 0.39, alpha: 1),
        NSColor(calibratedRed: 0.50, green: 0.58, blue: 0.43, alpha: 1),
    ]

    init(size: CGSize) {
        scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = StorybookPalette.cream
        StorybookBackdrop.add(
            to: scene,
            top: NSColor(calibratedRed: 0.34, green: 0.42, blue: 0.53, alpha: 1),
            bottom: NSColor(calibratedRed: 0.91, green: 0.82, blue: 0.68, alpha: 1),
            ground: NSColor(calibratedRed: 0.30, green: 0.25, blue: 0.22, alpha: 1)
        )
        buildInstrument(size: size)
        SampledInstrument.shared.volume = Float(SettingsStore.shared.maxVolume) * 0.82
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        play(index: Int(keyCode) % bars.count)
    }

    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}

    func handleMouseDown(position: CGPoint) {
        let width = scene.size.width * 0.78
        let left = (scene.size.width - width) / 2
        let normalized = min(0.999, max(0, (position.x - left) / width))
        play(index: Int(normalized * CGFloat(bars.count)))
    }

    func willEnd() {
        SampledInstrument.shared.stop()
    }

    private func buildInstrument(size: CGSize) {
        let totalWidth = size.width * 0.78
        let gap = max(8, totalWidth * 0.012)
        let barWidth = (totalWidth - gap * CGFloat(colors.count - 1)) / CGFloat(colors.count)
        let left = (size.width - totalWidth) / 2
        let centerY = size.height * 0.52

        for index in colors.indices {
            let height = size.height * (0.47 - CGFloat(index) * 0.018)
            let bar = SKShapeNode(rectOf: CGSize(width: barWidth, height: height), cornerRadius: barWidth * 0.22)
            bar.fillColor = colors[index]
            bar.strokeColor = NSColor.white.withAlphaComponent(0.34)
            bar.lineWidth = 2
            bar.position = CGPoint(
                x: left + barWidth / 2 + CGFloat(index) * (barWidth + gap),
                y: centerY
            )
            bar.zPosition = 10
            scene.addChild(bar)
            bars.append(bar)
        }

        let title = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        title.text = "нажми клавишу — сыграй ноту"
        title.fontColor = NSColor.white.withAlphaComponent(0.78)
        title.fontSize = max(18, min(size.width, size.height) * 0.028)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        title.zPosition = 20
        scene.addChild(title)
    }

    private func play(index: Int) {
        guard !bars.isEmpty else { return }
        let safeIndex = abs(index) % bars.count
        let bar = bars[safeIndex]
        bar.removeAllActions()
        bar.setScale(1)
        bar.run(.sequence([
            .scale(to: 0.94, duration: 0.055),
            .scale(to: 1.04, duration: 0.12),
            .scale(to: 1.0, duration: 0.16),
        ]))
        if SettingsStore.shared.soundEnabled {
            SampledInstrument.shared.play(scaleIndex: safeIndex, velocity: 88)
        }
    }
}

