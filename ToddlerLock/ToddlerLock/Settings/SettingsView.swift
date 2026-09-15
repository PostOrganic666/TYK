import SwiftUI
import CoreGraphics

/// One section in the Settings sidebar.
enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case play = "Play"
    case photos = "Photos"
    case exit = "Exit"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .play: return "gamecontroller.fill"
        case .photos: return "photo.on.rectangle"
        case .exit: return "rectangle.portrait.and.arrow.right"
        case .about: return "info.circle"
        }
    }
}

/// Settings window shown before locking. A sidebar layout like System
/// Settings, with Lock Now always visible at the bottom.
struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .play

    // Play
    @State private var selectedMode: PlayModeType = SettingsStore.shared.selectedMode
    @State private var playIntensity: PlayIntensity = SettingsStore.shared.playIntensity
    @State private var characterSet: LetterCharacterSet = SettingsStore.shared.characterSet
    @State private var soundEnabled: Bool = SettingsStore.shared.soundEnabled
    @State private var musicEnabled: Bool = SettingsStore.shared.musicEnabled
    @State private var maxVolume: Double = SettingsStore.shared.maxVolume
    @State private var sessionLimitMinutes: Int = SettingsStore.shared.sessionLimitMinutes

    // Photos
    @State private var photoSource: PhotoSource = SettingsStore.shared.photoSource
    @State private var showVideos: Bool = SettingsStore.shared.showVideos
    @State private var slideshowInterval: Double = SettingsStore.shared.slideshowInterval

    // Exit
    @State private var exitKeyCode: UInt16 = SettingsStore.shared.exitKeyCode
    @State private var exitModifiers: CGEventFlags = SettingsStore.shared.exitModifiers
    @State private var passwordEnabled: Bool = SettingsStore.shared.passwordEnabled
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordError: Bool = false
    @State private var passwordErrorMessage: String = ""

    var onLockNow: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar
                Divider()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            bottomBar
        }
        .frame(width: 720, height: 720)
    }

    private var sidebar: some View {
        List(selection: $selectedTab) {
            ForEach(SettingsTab.allCases) { tab in
                Label(tab.rawValue, systemImage: tab.icon).tag(tab)
            }
        }
        .listStyle(.sidebar)
        .frame(width: 170)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .play:
            PlaySettingsSection(
                selectedMode: $selectedMode,
                playIntensity: $playIntensity,
                characterSet: $characterSet,
                soundEnabled: $soundEnabled,
                musicEnabled: $musicEnabled,
                maxVolume: $maxVolume,
                sessionLimitMinutes: $sessionLimitMinutes
            )
        case .photos:
            PhotosSettingsSection(
                photoSource: $photoSource,
                showVideos: $showVideos,
                slideshowInterval: $slideshowInterval
            )
        case .exit:
            ExitSettingsSection(
                exitKeyCode: $exitKeyCode,
                exitModifiers: $exitModifiers,
                passwordEnabled: $passwordEnabled,
                password: $password,
                confirmPassword: $confirmPassword,
                showPasswordError: showPasswordError,
                passwordErrorMessage: passwordErrorMessage
            )
        case .about:
            AboutSettingsSection()
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 6) {
            Button(action: lockNow) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text("Lock Now")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)

            #if DEBUG
            Text("DEBUG: Auto-unlock after 60 seconds")
                .font(.caption2)
                .foregroundColor(.orange)
            #endif
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func lockNow() {
        // Play
        SettingsStore.shared.selectedMode = selectedMode
        SettingsStore.shared.playIntensity = playIntensity
        SettingsStore.shared.characterSet = characterSet
        SettingsStore.shared.soundEnabled = soundEnabled
        SettingsStore.shared.musicEnabled = musicEnabled
        SettingsStore.shared.maxVolume = maxVolume
        SettingsStore.shared.sessionLimitMinutes = sessionLimitMinutes

        // Photos
        SettingsStore.shared.photoSource = photoSource
        SettingsStore.shared.showVideos = showVideos
        SettingsStore.shared.slideshowInterval = slideshowInterval

        // Exit
        SettingsStore.shared.exitKeyCode = exitKeyCode
        SettingsStore.shared.exitModifiers = exitModifiers
        SettingsStore.shared.passwordEnabled = passwordEnabled

        if passwordEnabled {
            guard !password.isEmpty else {
                showPasswordError = true
                passwordErrorMessage = "Password cannot be empty"
                selectedTab = .exit
                return
            }
            guard password == confirmPassword else {
                showPasswordError = true
                passwordErrorMessage = "Passwords don't match"
                selectedTab = .exit
                return
            }
            KeychainManager.savePassword(password)
        }

        showPasswordError = false
        onLockNow?()
    }
}
