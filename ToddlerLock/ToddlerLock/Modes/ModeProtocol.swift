import AppKit
import SpriteKit

/// The available play modes. Raw values are persisted; never change them.
/// Case order drives the order of the mode cards in Settings.
enum PlayModeType: String, CaseIterable {
    case freePlay = "Free Play"
    case playComputer = "Play Computer"
    case camera = "Camera"
    case game = "Game"
    case character = "Character"
    case chill = "Chill"
    case slideshow = "Slideshow"
    case explore = "Explore"

    var isPhotoMode: Bool { self == .slideshow || self == .explore }

    var emoji: String {
        switch self {
        case .freePlay: return "🎨"
        case .playComputer: return "💻"
        case .camera: return "📸"
        case .game: return "🎮"
        case .character: return "🐾"
        case .chill: return "🌿"
        case .slideshow: return "🖼️"
        case .explore: return "👆"
        }
    }

    var blurb: String {
        switch self {
        case .freePlay: return "Colorful letters, shapes & rainbow trails"
        case .playComputer: return "A pretend Mac with a dock and 20 little apps"
        case .camera: return "A real camera view with silly filters. Nothing is saved"
        case .game: return "Pop floating bubbles to score points"
        case .character: return "A friendly creature follows the mouse"
        case .chill: return "Gentle emoji & soft colors for calm play"
        case .slideshow: return "Family photos and videos change on their own"
        case .explore: return "Arrow keys and clicks move through family photos"
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
