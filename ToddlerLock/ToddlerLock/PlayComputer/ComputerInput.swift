import AppKit
import Combine

/// Input feed for SwiftUI-hosted modes. Mouse events also arrive as real
/// NSEvents (synthesized by LockViewController at the virtual pointer),
/// so buttons, drags, and scroll views work as usual. This object adds what
/// SwiftUI on macOS 13 cannot get on its own: the pointer position for
/// hover effects, and key presses for typing.
final class ComputerInput: ObservableObject {
    static let shared = ComputerInput()

    struct KeyPress {
        enum Arrow { case up, down, left, right }

        let keyCode: UInt16
        let characters: String?

        var isReturn: Bool { keyCode == 36 || keyCode == 76 }
        var isDelete: Bool { keyCode == 51 || keyCode == 117 }
        var isSpace: Bool { keyCode == 49 }
        var isEscape: Bool { keyCode == 53 }
        var arrow: Arrow? {
            switch keyCode {
            case 126: return .up
            case 125: return .down
            case 123: return .left
            case 124: return .right
            default: return nil
            }
        }
        var isTab: Bool { keyCode == 48 }
        /// A single printable character, uppercased, or nil.
        var letter: String? {
            guard let c = characters?.first, c.isLetter || c.isNumber else { return nil }
            return String(c).uppercased()
        }
        /// Any single printable character (letters, digits, space, punctuation).
        var printable: Character? {
            guard let c = characters?.first, !c.isNewline, c.asciiValue.map({ $0 >= 32 && $0 < 127 }) ?? true else { return nil }
            if isReturn || isDelete || isEscape || isTab || arrow != nil { return nil }
            return c
        }
    }

    /// Pointer position in top-left coordinates of the mode's content view.
    @Published var pointer: CGPoint = .zero

    /// Whether the mouse button is currently down.
    @Published var isMouseDown = false

    /// The app that should receive typed keys (set by the window manager).
    @Published var focusedAppID: String?

    /// True on the lock screen (the shell draws nothing extra for the
    /// pointer; LockViewController draws the arrow). False in the DEBUG
    /// preview window, where the real cursor is visible.
    @Published var drawsOwnPointer = false

    /// Every key down, for all subscribers. Apps check `focusedAppID`.
    let keyDown = PassthroughSubject<KeyPress, Never>()

    private init() {}

    func send(keyCode: UInt16, characters: String?) {
        keyDown.send(KeyPress(keyCode: keyCode, characters: characters))
    }

    func reset() {
        pointer = .zero
        isMouseDown = false
        focusedAppID = nil
    }
}

/// Shorthand used by the desktop shell and apps.
typealias KeyPress = ComputerInput.KeyPress
