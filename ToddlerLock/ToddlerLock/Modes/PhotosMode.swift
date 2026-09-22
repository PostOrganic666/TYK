import AppKit
import SpriteKit
import Combine
import SwiftUI

/// Input feed for the photo modes. The mode turns key presses, clicks, and
/// scrolls into two commands, and the SwiftUI views subscribe to them.
///
/// Clicks and scrolls can arrive twice: the lock screen calls the mode and
/// also synthesizes a real NSEvent that reaches the catcher view. Both paths
/// come through here, and the rate limits below keep one gesture at one move.
final class PhotoInput: ObservableObject {
    enum Command {
        case next
        case previous
    }

    let commands = PassthroughSubject<Command, Never>()

    /// False once the mode ends. The views stop and release their players.
    @Published private(set) var isActive = true

    private var lastClick: TimeInterval = 0
    private var lastScroll: TimeInterval = 0

    /// Shortest gap between two moves from the same kind of gesture.
    private static let clickGap: TimeInterval = 0.25
    private static let scrollGap: TimeInterval = 0.35

    /// Scrolls smaller than this do nothing.
    private static let scrollThreshold: CGFloat = 2

    func send(_ command: Command) {
        commands.send(command)
    }

    /// A click. The right half moves forward, the left half moves back.
    func click(isRightHalf: Bool) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastClick > Self.clickGap else { return }
        lastClick = now
        send(isRightHalf ? .next : .previous)
    }

    /// A wheel or trackpad scroll. Down moves forward, up moves back.
    func scroll(deltaY: CGFloat) {
        guard abs(deltaY) >= Self.scrollThreshold else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastScroll > Self.scrollGap else { return }
        lastScroll = now
        send(deltaY < 0 ? .next : .previous)
    }

    func stop() {
        isActive = false
    }
}

/// Slideshow and Explore: the family's photos and videos, display only.
///
/// The mode shows pictures and nothing else. It has no share, edit, export,
/// or delete control, and videos play in a bare layer with no controls.
///
/// The mode never asks for photo access. While the Mac is locked, the event
/// tap swallows every key and click, so a system prompt could not be
/// answered. Without access the mode shows a parent-facing message, and the
/// Settings screen is where access is granted.
final class PhotosMode: PlayMode {
    let contentView: NSView?
    var spriteScene: SKScene? { nil }
    let style: PlayModeType

    private let input: PhotoInput
    private let size: CGSize

    /// Keys that move back in Explore: left arrow and up arrow.
    private static let backKeys: Set<UInt16> = [123, 126]

    init(size: CGSize, style: PlayModeType) {
        let input = PhotoInput()
        self.input = input
        self.style = style
        self.size = size

        let host = NSHostingView(rootView: PhotoModeRootView(style: style, input: input))
        host.frame = CGRect(origin: .zero, size: size)
        contentView = host
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        // Slideshow moves on for any key. Explore also moves back.
        if style == .explore, Self.backKeys.contains(keyCode) {
            input.send(.previous)
        } else {
            input.send(.next)
        }
    }

    func handleKeyUp(keyCode: UInt16) {}

    func handleMouseMove(position: CGPoint) {}

    func handleMouseDown(position: CGPoint) {
        input.click(isRightHalf: position.x >= size.width / 2)
    }

    func handleMouseDragged(position: CGPoint) {}

    func handleScroll(deltaY: CGFloat, at position: CGPoint) {
        input.scroll(deltaY: deltaY)
    }

    func willEnd() {
        input.stop()
    }
}
