import AppKit
import SpriteKit

/// The available play modes. Raw values are persisted; never change them.
/// Case order drives the order of the mode cards in Settings.
enum PlayModeType: String, CaseIterable {
    case letters = "Буквы"
    case animals = "Животные"
    case transport = "Транспорт"
    case musicStudio = "Музыка"

    static let featured = allCases

    var symbolName: String {
        switch self {
        case .letters: return "textformat"
        case .animals: return "pawprint.fill"
        case .transport: return "car.side.fill"
        case .musicStudio: return "music.quarternote.3"
        }
    }

    var blurb: String {
        switch self {
        case .letters: return "Все 33 русские буквы с чётким произношением"
        case .animals: return "Книжные звери появляются по одному и называют себя"
        case .transport: return "Поезд, трактор, автобус и другая техника"
        case .musicStudio: return "Настоящие семплы челесты вместо электронных гудков"
        }
    }
}

/// Protocol that all play modes conform to. A mode provides either a
/// SpriteKit scene or an AppKit/SwiftUI view, and receives input from the
/// InputEventBus (the real cursor is hidden and disassociated the whole
/// time; positions are virtual, origin bottom-left in view coordinates).
protocol PlayMode: AnyObject {
    /// SpriteKit modes provide a scene.
    var spriteScene: SKScene? { get }

    /// AppKit/SwiftUI modes provide a view. The lock view controller also
    /// synthesizes real NSEvents at the virtual pointer into the hosting
    /// window, so SwiftUI buttons, drags, and scroll views work as usual,
    /// and it draws an arrow cursor on top.
    var contentView: NSView? { get }

    func handleKeyDown(keyCode: UInt16, characters: String?)
    func handleKeyUp(keyCode: UInt16)
    func handleMouseMove(position: CGPoint)
    func handleMouseDown(position: CGPoint)
    func handleMouseDragged(position: CGPoint)
    func handleMouseUp(position: CGPoint)
    func handleScroll(deltaY: CGFloat, at position: CGPoint)

    /// The mode is about to go away: stop cameras, timers, players.
    func willEnd()
}

extension PlayMode {
    func handleMouseUp(position: CGPoint) {}
    func handleScroll(deltaY: CGFloat, at position: CGPoint) {}
    func willEnd() {}
}
