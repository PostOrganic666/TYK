import AppKit
import SwiftUI

/// Slideshow and Explore: kid-safe family photos and videos, display-only.
/// (Filled in by the photos work.)
final class PhotosMode: PlayMode {
    let contentView: NSView?
    let style: PlayModeType

    init(size: CGSize, style: PlayModeType) {
        self.style = style
        let host = NSHostingView(rootView: Text(style.rawValue).font(.largeTitle))
        host.frame = CGRect(origin: .zero, size: size)
        contentView = host
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {}
    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDown(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}
}
