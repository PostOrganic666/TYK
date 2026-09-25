import AppKit
import SpriteKit

enum StorybookPalette {
    static let ink = NSColor(calibratedRed: 0.18, green: 0.16, blue: 0.14, alpha: 1)
    static let cream = NSColor(calibratedRed: 0.97, green: 0.93, blue: 0.84, alpha: 1)
    static let sage = NSColor(calibratedRed: 0.54, green: 0.68, blue: 0.55, alpha: 1)
    static let sky = NSColor(calibratedRed: 0.77, green: 0.88, blue: 0.91, alpha: 1)
    static let dusk = NSColor(calibratedRed: 0.31, green: 0.39, blue: 0.50, alpha: 1)
    static let clay = NSColor(calibratedRed: 0.78, green: 0.42, blue: 0.30, alpha: 1)
    static let mustard = NSColor(calibratedRed: 0.86, green: 0.67, blue: 0.25, alpha: 1)
}

enum StorybookBackdrop {
    static func add(to scene: SKScene, top: NSColor, bottom: NSColor, ground: NSColor) {
        let background = SKSpriteNode(texture: gradientTexture(size: scene.size, top: top, bottom: bottom))
        background.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        background.size = scene.size
        background.zPosition = -100
        scene.addChild(background)

        let horizon = scene.size.height * 0.23
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: horizon))
        path.addCurve(
            to: CGPoint(x: scene.size.width, y: horizon * 0.92),
            control1: CGPoint(x: scene.size.width * 0.28, y: horizon * 1.30),
            control2: CGPoint(x: scene.size.width * 0.70, y: horizon * 0.62)
        )
        path.addLine(to: CGPoint(x: scene.size.width, y: 0))
        path.closeSubpath()
        let groundNode = SKShapeNode(path: path)
        groundNode.fillColor = ground
        groundNode.strokeColor = ground.withAlphaComponent(0.5)
        groundNode.lineWidth = 2
        groundNode.zPosition = -20
        scene.addChild(groundNode)
    }

    private static func gradientTexture(size: CGSize, top: NSColor, bottom: NSColor) -> SKTexture {
        let image = NSImage(size: size)
        image.lockFocus()
        NSGradient(starting: bottom, ending: top)?.draw(in: NSRect(origin: .zero, size: size), angle: 90)
        image.unlockFocus()
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}

struct StorybookPicture {
    let name: String
    let assetName: String
    let column: Int
    let rowFromTop: Int

    init(name: String, assetName: String = "storybook-sprites", column: Int, rowFromTop: Int) {
        self.name = name
        self.assetName = assetName
        self.column = column
        self.rowFromTop = rowFromTop
    }

    var texture: SKTexture {
        let sheet = SKTexture(imageNamed: assetName)
        sheet.filteringMode = .linear
        let columns: CGFloat = 4
        let rows: CGFloat = 3
        let rect = CGRect(
            x: CGFloat(column) / columns,
            y: 1 - CGFloat(rowFromTop + 1) / rows,
            width: 1 / columns,
            height: 1 / rows
        )
        let result = SKTexture(rect: rect, in: sheet)
        result.filteringMode = .linear
        return result
    }
}
