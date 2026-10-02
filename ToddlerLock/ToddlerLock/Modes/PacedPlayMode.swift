import AppKit
import SpriteKit

/// One shared pacing policy for every non-musical mode, including DEBUG preview.
/// Rejected presses are discarded, never queued. Release events remain unblocked.
final class PacedPlayMode: PlayMode {
    private let wrapped: PlayMode
    private var gate = PlayInteractionGate()

    var spriteScene: SKScene? { wrapped.spriteScene }
    var contentView: NSView? { wrapped.contentView }

    init(_ wrapped: PlayMode, startWithPause: Bool = false) {
        self.wrapped = wrapped
        if startWithPause {
            _ = gate.accept(at: ProcessInfo.processInfo.systemUptime,
                            minimumInterval: 0, speechBusy: false)
        }
    }

    private func acceptPress() -> Bool {
        gate.accept(at: ProcessInfo.processInfo.systemUptime,
                    minimumInterval: SettingsStore.shared.interactionPauseSeconds,
                    speechBusy: RussianSpeech.shared.isBusy)
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        guard acceptPress() else { return }
        wrapped.handleKeyDown(keyCode: keyCode, characters: characters)
    }
    func handleMouseDown(position: CGPoint) {
        guard acceptPress() else { return }
        wrapped.handleMouseDown(position: position)
    }
    func handleKeyUp(keyCode: UInt16) { wrapped.handleKeyUp(keyCode: keyCode) }
    func handleMouseMove(position: CGPoint) { wrapped.handleMouseMove(position: position) }
    func handleMouseDragged(position: CGPoint) { wrapped.handleMouseDragged(position: position) }
    func handleMouseUp(position: CGPoint) { wrapped.handleMouseUp(position: position) }
    func handleScroll(deltaY: CGFloat, at position: CGPoint) {
        wrapped.handleScroll(deltaY: deltaY, at: position)
    }
    func willEnd() { wrapped.willEnd() }
}
