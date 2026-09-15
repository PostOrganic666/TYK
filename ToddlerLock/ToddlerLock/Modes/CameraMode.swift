import AppKit
import SwiftUI

/// Camera play: the real camera view with silly filters, a shutter, and a
/// shot counter. Nothing is ever saved. (Filled in by the camera work.)
final class CameraMode: PlayMode {
    let contentView: NSView?

    init(size: CGSize) {
        let host = NSHostingView(rootView: Text("Camera").font(.largeTitle))
        host.frame = CGRect(origin: .zero, size: size)
        contentView = host
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {}
    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDown(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}
}
