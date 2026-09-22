import Foundation
import CoreGraphics

/// Stores app settings in UserDefaults. Password stored separately (Keychain in Phase 4).
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    // MARK: - Exit Shortcut

    var exitKeyCode: UInt16 {
        get { UInt16(defaults.integer(forKey: "exitKeyCode").nonZeroOr(53)) } // 53 = Escape
        set { defaults.set(Int(newValue), forKey: "exitKeyCode") }
    }

    var exitModifierFlags: UInt64 {
        get {
            let stored = defaults.integer(forKey: "exitModifierFlags")
            if stored == 0 {
                // Default: Command + Shift
                return CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue
            }
            return UInt64(stored)
        }
        set { defaults.set(Int(newValue), forKey: "exitModifierFlags") }
    }

    var exitModifiers: CGEventFlags {
        get { CGEventFlags(rawValue: exitModifierFlags) }
        set { exitModifierFlags = newValue.rawValue }
    }

    // MARK: - Unlock check

    /// What the exit shortcut asks for before the lock ends.
    var unlockGate: UnlockGate {
        get {
            if let raw = defaults.string(forKey: "unlockGate"), let gate = UnlockGate(rawValue: raw) {
                return gate
            }
            // Older versions stored only the password switch.
            return passwordEnabled ? .password : .none
        }
        set {
            defaults.set(newValue.rawValue, forKey: "unlockGate")
            passwordEnabled = newValue == .password
        }
    }

    // MARK: - Password

    var passwordEnabled: Bool {
        get { defaults.bool(forKey: "passwordEnabled") }
        set { defaults.set(newValue, forKey: "passwordEnabled") }
    }

    /// For Phase 1, store password directly. Phase 4 moves this to Keychain.
    var password: String {
        get { defaults.string(forKey: "lockPassword") ?? "" }
        set { defaults.set(newValue, forKey: "lockPassword") }
    }

    // MARK: - Mode

    var selectedMode: PlayModeType {
        get {
            guard let raw = defaults.string(forKey: "selectedMode"),
                  let mode = PlayModeType(rawValue: raw) else {
                return .freePlay
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: "selectedMode") }
    }

    // MARK: - Sound

    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: "soundEnabled") == nil { return true }
            return defaults.bool(forKey: "soundEnabled")
        }
        set { defaults.set(newValue, forKey: "soundEnabled") }
    }

    var musicEnabled: Bool {
        get { defaults.bool(forKey: "musicEnabled") }
        set { defaults.set(newValue, forKey: "musicEnabled") }
    }

    // MARK: - Play style, volume, timer

    /// Infant / Toddler / Lively. Drives contrast, size, speed, particle
    /// counts, and volume in every play mode.
    var playIntensity: PlayIntensity {
        get {
            guard let raw = defaults.string(forKey: "playIntensity"),
                  let value = PlayIntensity(rawValue: raw) else { return .toddler }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: "playIntensity") }
    }

    /// Ceiling for everything the app plays, 0.1...1.0. Applied at the
    /// audio-engine mixer and to video playback.
    var maxVolume: Double {
        get {
            if defaults.object(forKey: "maxVolume") == nil { return 1.0 }
            return min(max(defaults.double(forKey: "maxVolume"), 0.1), 1.0)
        }
        set {
            defaults.set(newValue, forKey: "maxVolume")
            SoundManager.shared.maxVolume = Float(newValue)
        }
    }

    /// Optional play timer in minutes. 0 means off (the default). When the
    /// timer ends, the screen changes to a calm break scene. The exit
    /// shortcut still controls the exit.
    var sessionLimitMinutes: Int {
        get { defaults.integer(forKey: "sessionLimitMinutes") }
        set { defaults.set(newValue, forKey: "sessionLimitMinutes") }
    }

    // MARK: - Photos

    var photoSource: PhotoSource {
        get {
            guard let raw = defaults.string(forKey: "photoSource"),
                  let value = PhotoSource(rawValue: raw) else { return .recents }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: "photoSource") }
    }

    /// PHAsset local identifiers when photoSource == .selectedPhotos.
    var selectedPhotoIDs: [String] {
        get { defaults.stringArray(forKey: "selectedPhotoIDs") ?? [] }
        set { defaults.set(newValue, forKey: "selectedPhotoIDs") }
    }

    /// Album local identifiers when photoSource == .includedAlbums.
    var includedAlbumIDs: [String] {
        get { defaults.stringArray(forKey: "includedAlbumIDs") ?? [] }
        set { defaults.set(newValue, forKey: "includedAlbumIDs") }
    }

    /// Album local identifiers when photoSource == .allExceptAlbums.
    var excludedAlbumIDs: [String] {
        get { defaults.stringArray(forKey: "excludedAlbumIDs") ?? [] }
        set { defaults.set(newValue, forKey: "excludedAlbumIDs") }
    }

    /// Include the library's videos in the photo modes. Display-only.
    var showVideos: Bool {
        get {
            if defaults.object(forKey: "showVideos") == nil { return true }
            return defaults.bool(forKey: "showVideos")
        }
        set { defaults.set(newValue, forKey: "showVideos") }
    }

    /// Seconds between slideshow advances.
    var slideshowInterval: Double {
        get {
            let stored = defaults.double(forKey: "slideshowInterval")
            return stored == 0 ? 6.0 : stored
        }
        set { defaults.set(newValue, forKey: "slideshowInterval") }
    }

    // MARK: - Character Set

    var characterSet: LetterCharacterSet {
        get {
            guard let raw = defaults.string(forKey: "characterSet"),
                  let cs = LetterCharacterSet(rawValue: raw) else {
                return .english
            }
            return cs
        }
        set { defaults.set(newValue.rawValue, forKey: "characterSet") }
    }

    private init() {}
}

/// The check the exit shortcut runs. Raw values are persisted.
enum UnlockGate: String, CaseIterable, Identifiable {
    case none = "Shortcut only"
    case math = "Math question"
    case password = "Password"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .none: return "The shortcut alone ends the lock."
        case .math: return "The shortcut opens a multiplication question. Grown-ups solve it in a second."
        case .password: return "The shortcut asks for your password."
        }
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}
