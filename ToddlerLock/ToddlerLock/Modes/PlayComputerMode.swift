import AppKit
import SwiftUI

/// Play Computer: a pretend Mac desktop hosted in SwiftUI. Mouse events
/// reach the SwiftUI views as real NSEvents; keys go through ComputerInput.
final class PlayComputerMode: PlayMode {
    let contentView: NSView?
    private let input = ComputerInput.shared

    init(size: CGSize) {
        input.reset()
        let host = NSHostingView(rootView: DesktopView())
        host.frame = CGRect(origin: .zero, size: size)
        contentView = host
        SoundManager.shared.styleVolume = PlayStyle.current.volumeScale
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        input.keyDown.send(ComputerInput.KeyPress(keyCode: keyCode, characters: characters))
    }

    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDown(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}

    func willEnd() {
        input.reset()
        SoundManager.shared.styleVolume = 1.0
    }
}
