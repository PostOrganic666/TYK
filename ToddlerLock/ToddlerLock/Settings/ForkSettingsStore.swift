import Foundation
import CoreGraphics

/// Settings used by the fork. The upstream photo, camera, language-pack and
/// background-music preferences are intentionally not part of this build.
final class SettingsStore {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard

    var exitKeyCode: UInt16 {
        get { UInt16(defaults.integer(forKey: "exitKeyCode").nonZeroOr(53)) }
        set { defaults.set(Int(newValue), forKey: "exitKeyCode") }
    }

    var exitModifierFlags: UInt64 {
        get {
            let stored = defaults.integer(forKey: "exitModifierFlags")
            return stored == 0
                ? CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue
                : UInt64(stored)
        }
        set { defaults.set(Int(newValue), forKey: "exitModifierFlags") }
    }

    var exitModifiers: CGEventFlags {
        get { CGEventFlags(rawValue: exitModifierFlags) }
        set { exitModifierFlags = newValue.rawValue }
    }

    var unlockGate: UnlockGate {
        get {
            guard let raw = defaults.string(forKey: "unlockGate"),
                  let gate = UnlockGate(rawValue: raw) else { return .none }
            return gate
        }
        set { defaults.set(newValue.rawValue, forKey: "unlockGate") }
    }

    var selectedMode: PlayModeType {
        get {
            guard let raw = defaults.string(forKey: "selectedMode"),
                  let mode = PlayModeType(rawValue: raw) else { return .letters }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: "selectedMode") }
    }

    var soundEnabled: Bool {
        get {
            if defaults.object(forKey: "soundEnabled") == nil { return true }
            return defaults.bool(forKey: "soundEnabled")
        }
        set { defaults.set(newValue, forKey: "soundEnabled") }
    }

    var maxVolume: Double {
        get {
            if defaults.object(forKey: "maxVolume") == nil { return 0.75 }
            return min(max(defaults.double(forKey: "maxVolume"), 0.1), 1.0)
        }
        set {
            defaults.set(newValue, forKey: "maxVolume")
            SampledInstrument.shared.volume = Float(newValue)
        }
    }

    var sessionLimitMinutes: Int {
        get { defaults.integer(forKey: "sessionLimitMinutes") }
        set { defaults.set(newValue, forKey: "sessionLimitMinutes") }
    }

    private init() {}
}

enum UnlockGate: String, CaseIterable, Identifiable {
    case none = "shortcut"
    case math = "math"
    case password = "password"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Только комбинацию"
        case .math: return "Пример"
        case .password: return "Пароль"
        }
    }

    var blurb: String {
        switch self {
        case .none: return "Комбинация сразу завершает детский режим."
        case .math: return "После комбинации нужно решить простой пример."
        case .password: return "После комбинации нужно ввести пароль."
        }
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int { self == 0 ? fallback : self }
}

