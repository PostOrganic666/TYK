import AppKit
import SpriteKit
import Combine
import SwiftUI

/// Key actions forwarded from the event tap into the SwiftUI view. Mouse
/// clicks reach the SwiftUI buttons directly as synthesized NSEvents, but
/// keys only arrive through `handleKeyDown`, so this object relays them.
final class CameraModeInput: ObservableObject {
    enum Action {
        case shutter
        case cycleFilter(forward: Bool)
        case selectFilter(Int)
        case cycleStrip
    }

    let actions = PassthroughSubject<Action, Never>()

    func send(_ action: Action) {
        actions.send(action)
    }
}

/// Camera play: the real camera view with silly filters, a shutter, and a
/// shot counter. Nothing is ever saved: the capture session has an input
/// and a preview layer and no outputs at all.
final class CameraMode: PlayMode {
    let contentView: NSView?
    var spriteScene: SKScene? { nil }
    private let camera: PlayCameraController
    private let input = CameraModeInput()

    init(size: CGSize) {
        // This mode is always created on the main thread (LockViewController
        // builds it during viewDidAppear), which is where PlayCameraController
        // requires isolation.
        let cam = MainActor.assumeIsolated { PlayCameraController() }
        camera = cam
        let host = NSHostingView(rootView: CameraPlayView(camera: cam, input: input))
        host.frame = CGRect(origin: .zero, size: size)
        contentView = host
        // Locked sessions can't answer a system permission dialog, so this
        // must never prompt. If access isn't already granted, the view
        // shows a parent-facing message instead.
        MainActor.assumeIsolated {
            cam.start(allowPrompt: false)
        }
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) {
        switch keyCode {
        case 49, 36, 76: // space, return, numpad enter
            input.send(.shutter)
            return
        case 123: // left arrow
            input.send(.cycleFilter(forward: false))
            return
        case 124: // right arrow
            input.send(.cycleFilter(forward: true))
            return
        default:
            break
        }

        guard let key = characters?.lowercased(), key.count == 1, let scalar = key.unicodeScalars.first else { return }

        if key == "f" {
            input.send(.cycleFilter(forward: true))
        } else if key == "m" {
            input.send(.cycleStrip)
        } else if let digit = Int(key), (1...9).contains(digit) {
            input.send(.selectFilter(digit))
        } else if CharacterSet.letters.contains(scalar) {
            input.send(.shutter)
        }
    }

    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDown(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}

    func willEnd() {
        MainActor.assumeIsolated {
            camera.stop()
        }
    }
}
