import AppKit
import SpriteKit

/// A calm modern alphabet: the letter remains above three progressively revealed cards.
final class AlphabetMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }

    private var progress = AlphabetProgress()
    private let letterNode = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let noteNode = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let hintNode = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let cardsNode = SKNode()
    private let colors: [NSColor] = [StorybookPalette.clay,
        NSColor(calibratedRed: 0.18, green: 0.44, blue: 0.59, alpha: 1),
        NSColor(calibratedRed: 0.30, green: 0.49, blue: 0.35, alpha: 1)]

    init(size: CGSize) {
        scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.90, alpha: 1)
        letterNode.verticalAlignmentMode = .center
        letterNode.position = CGPoint(x: size.width / 2, y: size.height * 0.77)
        letterNode.fontSize = min(size.height * 0.26, size.width * 0.23)
        scene.addChild(letterNode)
        noteNode.fontColor = StorybookPalette.ink.withAlphaComponent(0.65)
        noteNode.fontSize = max(16, size.height * 0.026)
        noteNode.position = CGPoint(x: size.width / 2, y: size.height * 0.60)
        scene.addChild(noteNode)
        hintNode.fontColor = StorybookPalette.ink.withAlphaComponent(0.55)
        hintNode.fontSize = max(16, size.height * 0.025)
        hintNode.position = CGPoint(x: size.width / 2, y: size.height * 0.065)
        scene.addChild(hintNode)
        scene.addChild(cardsNode)
        showLetter()
        hintNode.text = "Тык — первая картинка"
        RussianSpeech.shared.speak(progress.letter.spokenName)
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) { advance() }
    func handleMouseDown(position: CGPoint) { advance() }
    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}
    func willEnd() { RussianSpeech.shared.stop() }

    private func advance() {
        progress.advance()
        if progress.stage == 0 {
            cardsNode.removeAllChildren()
            showLetter()
            RussianSpeech.shared.speak(progress.letter.spokenName)
        } else {
            let picture = AlphabetCards.examples[progress.letterIndex][progress.stage - 1]
            addCard(picture, at: progress.stage - 1)
            RussianSpeech.shared.speak(picture.name)
        }
        hintNode.text = progress.stage == 3 ? "Тык — следующая буква" : "Тык — ещё картинка"
    }

    private func showLetter() {
        let glyph = progress.letter.glyph
        letterNode.text = glyph + " " + glyph.lowercased()
        letterNode.fontColor = colors[progress.letterIndex % colors.count]
        letterNode.removeAllActions()
        letterNode.alpha = 0
        letterNode.run(.fadeIn(withDuration: 0.22))
        noteNode.text = ["Ъ", "Ь", "Ы"].contains(glyph)
            ? "Находим букву внутри слова"
            : glyph == "Й" ? "В начале и внутри слова" : nil
    }

    private func addCard(_ picture: StorybookPicture, at index: Int) {
        let size = scene.size
        let width = size.width * 0.275
        let height = min(size.height * 0.42, width * 1.27)
        let group = SKNode()
        group.position = CGPoint(x: size.width * (0.19 + CGFloat(index) * 0.31), y: size.height * 0.34)
        let background = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 24)
        background.fillColor = .white
        background.strokeColor = colors[progress.letterIndex % colors.count].withAlphaComponent(0.16)
        background.lineWidth = 2
        group.addChild(background)
        let sprite = SKSpriteNode(texture: picture.texture)
        let side = min(width * 0.92, height * 0.78)
        sprite.size = CGSize(width: side, height: side)
        sprite.position.y = height * 0.065
        group.addChild(sprite)

        // One label per character makes the target letter visible even in Ъ/Ы/Ь examples.
        let caption = SKNode()
        let fontSize = min(size.height * 0.035, width / CGFloat(max(8, picture.name.count)) * 1.25)
        var totalWidth: CGFloat = 0
        for character in picture.name {
            let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
            label.text = String(character)
            label.fontSize = fontSize
            label.horizontalAlignmentMode = .left
            label.fontColor = String(character).uppercased() == progress.letter.glyph
                ? colors[progress.letterIndex % colors.count] : StorybookPalette.ink
            label.position.x = totalWidth
            totalWidth += max(label.frame.width, character == " " ? fontSize * 0.3 : 0)
            caption.addChild(label)
        }
        caption.position = CGPoint(x: -totalWidth / 2, y: -height * 0.39)
        group.addChild(caption)
        group.alpha = 0
        group.setScale(0.94)
        cardsNode.addChild(group)
        group.run(.group([.fadeIn(withDuration: 0.22), .scale(to: 1, duration: 0.22)]))
    }
}
