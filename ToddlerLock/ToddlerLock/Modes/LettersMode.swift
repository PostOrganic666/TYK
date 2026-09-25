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
        letterNode.removeAllActions()
        letterNode.text = letter.glyph
        letterNode.alpha = 0
        letterNode.setScale(0.86)
        let appear = SKAction.group([
            .fadeIn(withDuration: 0.18),
            .scale(to: 1.06, duration: 0.18),
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        letterNode.run(.sequence([appear, settle]))
        hintNode.run(.fadeAlpha(to: 0.18, duration: 0.25))
        RussianSpeech.shared.speak(letter.spokenName)
        if SettingsStore.shared.soundEnabled {
            SampledInstrument.shared.volume = Float(SettingsStore.shared.maxVolume) * 0.55
            SampledInstrument.shared.play(scaleIndex: RussianAlphabet.letters.firstIndex(where: { $0.glyph == letter.glyph }) ?? 0,
                                           velocity: 54)
        }
    }
}

