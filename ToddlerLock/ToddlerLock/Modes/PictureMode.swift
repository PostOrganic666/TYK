import AppKit
import SpriteKit

enum PictureCollection {
    case animals
    case transport

    var pictures: [StorybookPicture] {
        switch self {
        case .animals:
            return [
                .init(name: "медведь", column: 0, rowFromTop: 0),
                .init(name: "лиса", column: 1, rowFromTop: 0),
                .init(name: "заяц", column: 2, rowFromTop: 0),
                .init(name: "ёжик", column: 3, rowFromTop: 0),
                .init(name: "кот", column: 0, rowFromTop: 1),
                .init(name: "собака", column: 1, rowFromTop: 1),
            ]
        case .transport:
            return [
                .init(name: "трактор", column: 2, rowFromTop: 1),
                .init(name: "поезд", column: 3, rowFromTop: 1),
                .init(name: "автобус", column: 0, rowFromTop: 2),
                .init(name: "экскаватор", column: 1, rowFromTop: 2),
                .init(name: "самолёт", column: 2, rowFromTop: 2),
                .init(name: "кораблик", column: 3, rowFromTop: 2),
            ]
        }
    }
}

/// A quiet cause-and-effect scene with one recognizable illustration at a time.
final class PictureMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }

    private let collection: PictureCollection
    private let pictures: [StorybookPicture]
    private let titleNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var pictureNode: SKSpriteNode?
    private var index = 0

    init(size: CGSize, collection: PictureCollection) {
        self.collection = collection
        self.pictures = collection.pictures
        scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = StorybookPalette.cream

        let colors: (NSColor, NSColor, NSColor) = collection == .animals
            ? (StorybookPalette.sky, StorybookPalette.cream, StorybookPalette.sage)
            : (NSColor(calibratedRed: 0.70, green: 0.83, blue: 0.90, alpha: 1),
               NSColor(calibratedRed: 0.94, green: 0.87, blue: 0.72, alpha: 1),
               NSColor(calibratedRed: 0.69, green: 0.59, blue: 0.43, alpha: 1))
        StorybookBackdrop.add(to: scene, top: colors.0, bottom: colors.1, ground: colors.2)

        titleNode.fontColor = StorybookPalette.ink
        titleNode.fontSize = max(28, min(size.width, size.height) * 0.055)
        titleNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        titleNode.zPosition = 20
        scene.addChild(titleNode)
        show(pictures[0], speaks: false)
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) { advance() }
    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}
    func handleMouseDown(position: CGPoint) { advance() }

    func willEnd() {
        RussianSpeech.shared.stop()
    }

    private func advance() {
        index = (index + 1) % pictures.count
        show(pictures[index], speaks: true)
    }

    private func show(_ picture: StorybookPicture, speaks: Bool) {
        if let old = pictureNode {
            old.removeAllActions()
            old.run(.sequence([
                .group([.fadeOut(withDuration: 0.14), .scale(to: 0.92, duration: 0.14)]),
                .removeFromParent(),
            ]))
        }

        let node = SKSpriteNode(texture: picture.texture)
        let side = min(scene.size.width * 0.58, scene.size.height * 0.62)
        node.size = CGSize(width: side, height: side)
        node.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.53)
        node.alpha = 0
        node.setScale(0.88)
        node.zPosition = 10
        scene.addChild(node)
        pictureNode = node

        let arrival = SKAction.group([
            .fadeIn(withDuration: 0.22),
            .scale(to: 1.04, duration: 0.22),
        ])
        node.run(.sequence([arrival, .scale(to: 1.0, duration: 0.16)]))

        titleNode.text = picture.name
        titleNode.alpha = 0
        titleNode.run(.fadeIn(withDuration: 0.24))

        guard speaks else { return }
        RussianSpeech.shared.speak(picture.name)
        if SettingsStore.shared.soundEnabled {
            SampledInstrument.shared.volume = Float(SettingsStore.shared.maxVolume) * 0.48
            SampledInstrument.shared.play(scaleIndex: index, velocity: 48)
        }
    }
}

