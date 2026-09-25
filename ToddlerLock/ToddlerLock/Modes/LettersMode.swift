import AppKit
import SpriteKit

/// One large Russian letter at a time: no particles, emoji, or visual noise.
final class LettersMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }

    private let letterNode = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let hintNode = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private var clickIndex = 0
    private var appearanceIndex = 0
    private var letterPositions: [CGPoint] = []
    private let letterScales: [CGFloat] = [0.72, 1.05, 0.86, 0.96, 0.68, 1.10]
    private let letterColors: [NSColor] = [
        NSColor(calibratedRed: 0.75, green: 0.25, blue: 0.18, alpha: 1),
        NSColor(calibratedRed: 0.16, green: 0.43, blue: 0.65, alpha: 1),
        NSColor(calibratedRed: 0.23, green: 0.50, blue: 0.34, alpha: 1),
        NSColor(calibratedRed: 0.51, green: 0.30, blue: 0.61, alpha: 1),
        NSColor(calibratedRed: 0.82, green: 0.50, blue: 0.10, alpha: 1),
        NSColor(calibratedRed: 0.12, green: 0.48, blue: 0.50, alpha: 1),
    ]

    init(size: CGSize) {
        scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = StorybookPalette.cream
        StorybookBackdrop.add(
            to: scene,
            top: NSColor(calibratedRed: 0.95, green: 0.89, blue: 0.78, alpha: 1),
            bottom: NSColor(calibratedRed: 0.78, green: 0.88, blue: 0.84, alpha: 1),
            ground: NSColor(calibratedRed: 0.64, green: 0.72, blue: 0.52, alpha: 1)
        )

        letterNode.text = "А"
        letterNode.fontColor = StorybookPalette.ink
        letterNode.fontSize = min(size.width, size.height) * 0.43
        letterNode.verticalAlignmentMode = .center
        letterNode.horizontalAlignmentMode = .center
        letterNode.position = CGPoint(x: size.width / 2, y: size.height * 0.56)
        letterNode.zPosition = 10
        scene.addChild(letterNode)

        letterPositions = [
            CGPoint(x: size.width * 0.28, y: size.height * 0.66),
            CGPoint(x: size.width * 0.70, y: size.height * 0.51),
            CGPoint(x: size.width * 0.48, y: size.height * 0.69),
            CGPoint(x: size.width * 0.27, y: size.height * 0.43),
            CGPoint(x: size.width * 0.72, y: size.height * 0.70),
            CGPoint(x: size.width * 0.51, y: size.height * 0.48),
        ]
        applyAppearance(index: 0)

        hintNode.text = "нажми любую клавишу"
        hintNode.fontColor = StorybookPalette.ink.withAlphaComponent(0.48)
        hintNode.fontSize = max(18, min(size.width, size.height) * 0.026)
        hintNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        hintNode.zPosition = 10
        scene.addChild(hintNode)
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        show(RussianAlphabet.letter(for: keyCode, characters: characters))
    }

    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}

    func handleMouseDown(position: CGPoint) {
        clickIndex = (clickIndex + 1) % RussianAlphabet.letters.count
        show(RussianAlphabet.letters[clickIndex])
    }

    func willEnd() {
        RussianSpeech.shared.stop()
    }

    private func show(_ letter: RussianLetter) {
        appearanceIndex = (appearanceIndex + 1) % letterColors.count
        let targetScale = letterScales[appearanceIndex]
        letterNode.removeAllActions()
        letterNode.text = letter.glyph
        applyAppearance(index: appearanceIndex)
        letterNode.alpha = 0
        letterNode.setScale(targetScale * 0.82)
        let appear = SKAction.group([
            .fadeIn(withDuration: 0.18),
            .scale(to: targetScale * 1.06, duration: 0.18),
        ])
        let settle = SKAction.scale(to: targetScale, duration: 0.12)
        letterNode.run(.sequence([appear, settle]))
        hintNode.run(.fadeAlpha(to: 0.18, duration: 0.25))
        RussianSpeech.shared.speak(letter.spokenName)
        if SettingsStore.shared.soundEnabled {
            SampledInstrument.shared.volume = Float(SettingsStore.shared.maxVolume) * 0.55
            SampledInstrument.shared.play(scaleIndex: RussianAlphabet.letters.firstIndex(where: { $0.glyph == letter.glyph }) ?? 0,
                                           velocity: 54)
        }
    }

    private func applyAppearance(index: Int) {
        let safeIndex = index % letterColors.count
        letterNode.fontColor = letterColors[safeIndex]
        letterNode.position = letterPositions[safeIndex]
        letterNode.setScale(letterScales[safeIndex])
    }
}
