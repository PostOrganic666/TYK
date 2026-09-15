import AppKit

/// How much stimulation a play session delivers. Infant switches every
/// scene to high-contrast black and white with slow, big, quiet motion;
/// Lively speeds everything up and adds more of it.
enum PlayIntensity: String, CaseIterable, Identifiable {
    // Raw values are persisted. Never change them.
    case infant = "Infant"
    case toddler = "Toddler"
    case lively = "Lively"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .infant: return "High-contrast black and white. Slow, big, and quiet. For babies under 1."
        case .toddler: return "Bright colors, sounds, and sparkles on every key."
        case .lively: return "Faster, bigger, and more of everything."
        }
    }
}

/// The concrete knobs the modes read. Derived from the intensity so that
/// every mode applies the same rules.
struct PlayStyle {
    let intensity: PlayIntensity

    static var current: PlayStyle {
        PlayStyle(intensity: SettingsStore.shared.playIntensity)
    }

    /// Black background, white shapes, one red accent. No emoji.
    var highContrast: Bool { intensity == .infant }

    var sizeScale: CGFloat {
        switch intensity {
        case .infant: return 1.5
        case .toddler: return 1.0
        case .lively: return 1.15
        }
    }

    /// Durations are divided by this.
    var speedScale: CGFloat {
        switch intensity {
        case .infant: return 0.6
        case .toddler: return 1.0
        case .lively: return 1.45
        }
    }

    var particleScale: CGFloat {
        switch intensity {
        case .infant: return 0.35
        case .toddler: return 1.0
        case .lively: return 1.8
        }
    }

    /// Multiplier applied on top of the parent's max volume.
    var volumeScale: Float {
        intensity == .infant ? 0.5 : 1.0
    }

    /// How many objects a single key or click spawns.
    var spawnMultiplier: Int {
        intensity == .lively ? 2 : 1
    }

    static let highContrastPalette: [NSColor] = [.white, .white, .white, .white, .systemRed]

    func background(_ normal: NSColor) -> NSColor {
        highContrast ? .black : normal
    }

    func palette(_ normal: [NSColor]) -> [NSColor] {
        highContrast ? PlayStyle.highContrastPalette : normal
    }

    func duration(_ base: TimeInterval) -> TimeInterval {
        base / Double(speedScale)
    }

    func count(_ base: Int) -> Int {
        max(1, Int((CGFloat(base) * particleScale).rounded()))
    }
}
