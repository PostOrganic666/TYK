import SwiftUI
import AppKit
import CoreGraphics

/// The Settings window the parent uses before locking. One page, no
/// scrolling at the default size.
///
/// The mode grid on top decides the "For this mode" panel on the right:
/// letters for Free Play and Character, photos for Slideshow and Explore,
/// camera for Camera, both access rows for Play Computer. Play, Sound,
/// and Exit apply to every mode and stay put.
struct SettingsView: View {
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
    @State private var selectedPhotoIDs: [String] = SettingsStore.shared.selectedPhotoIDs
    @State private var includedAlbumIDs: [String] = SettingsStore.shared.includedAlbumIDs
    @State private var excludedAlbumIDs: [String] = SettingsStore.shared.excludedAlbumIDs
    @State private var showVideos: Bool = SettingsStore.shared.showVideos
    @State private var slideshowInterval: Double = SettingsStore.shared.slideshowInterval

    // Exit
    @State private var exitKeyCode: UInt16 = SettingsStore.shared.exitKeyCode
    @State private var exitModifiers: CGEventFlags = SettingsStore.shared.exitModifiers
    @State private var passwordEnabled: Bool = SettingsStore.shared.passwordEnabled
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var passwordError: String?

    // Access
    @State private var photosAllowed: Bool = PhotoLibraryService.accessAlreadyGranted
    @State private var cameraAllowed: Bool = PlayCameraController.accessAlreadyGranted

    var onLockNow: (() -> Void)?

    static let contentSize = NSSize(width: 760, height: 600)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                ModeGrid(selectedMode: $selectedMode)

                HStack(alignment: .top, spacing: 14) {
                    SettingsPanel(title: "Play") {
                        PlayPanel(
                            playIntensity: $playIntensity,
                            soundEnabled: $soundEnabled,
                            musicEnabled: $musicEnabled,
                            maxVolume: $maxVolume,
                            sessionLimitMinutes: $sessionLimitMinutes
                        )
                    }
                    SettingsPanel(title: "For \(selectedMode.rawValue)") {
                        ModePanel(
                            selectedMode: selectedMode,
                            characterSet: $characterSet,
                            photosAllowed: $photosAllowed,
                            cameraAllowed: $cameraAllowed,
                            photoSource: $photoSource,
                            selectedPhotoIDs: $selectedPhotoIDs,
                            includedAlbumIDs: $includedAlbumIDs,
                            excludedAlbumIDs: $excludedAlbumIDs,
                            showVideos: $showVideos,
                            slideshowInterval: $slideshowInterval
                        )
                        .id(selectedMode)
                        .transition(.opacity)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)

                SettingsPanel(title: "Exit") {
                    ExitPanel(
                        exitKeyCode: $exitKeyCode,
                        exitModifiers: $exitModifiers,
                        passwordEnabled: $passwordEnabled,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        passwordError: passwordError
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()
            bottomBar
        }
        .controlSize(.small)
        .frame(minWidth: 720, minHeight: 560)
        .background(WindowConfigurator(contentSize: Self.contentSize,
                                       minSize: NSSize(width: 720, height: 560)))
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshAccess()
        }
        .onChange(of: passwordEnabled) { _ in passwordError = nil }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if let need = pendingAccess {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
                Text(need.message)
                    .font(.callout)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Button(need.buttonTitle, action: need.action)
            } else {
                #if DEBUG
                Text("Debug build. The lock opens on its own after 60 seconds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #else
                Text("Grown-ups leave with the exit shortcut.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #endif
            }

            Spacer(minLength: 12)

            Button(action: lockNow) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text("Lock Now: \(selectedMode.rawValue)")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .padding(.horizontal, 18)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .help("Start \(selectedMode.rawValue) and lock the screen.")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    /// The access the selected mode needs and does not have yet. Locking is
    /// never blocked: each mode has its own parent-facing screen.
    private struct PendingAccess {
        let message: String
        let buttonTitle: String
        let action: () -> Void
    }

    private var pendingAccess: PendingAccess? {
        if selectedMode.requiresPhotosAccess && !photosAllowed {
            return PendingAccess(
                message: "\(selectedMode.rawValue) shows your photos. Photos access is off.",
                buttonTitle: "Allow Photos…"
            ) {
                AccessRequester.requestPhotos { photosAllowed = $0 }
            }
        }
        if selectedMode.requiresCameraAccess && !cameraAllowed {
            return PendingAccess(
                message: "Camera shows the live camera view. Camera access is off.",
                buttonTitle: "Allow Camera…"
            ) {
                AccessRequester.requestCamera { cameraAllowed = $0 }
            }
        }
        return nil
    }

    private func refreshAccess() {
        photosAllowed = PhotoLibraryService.accessAlreadyGranted
        cameraAllowed = PlayCameraController.accessAlreadyGranted
    }

    // MARK: - Lock

    private func lockNow() {
        let store = SettingsStore.shared
        store.selectedMode = selectedMode
        store.playIntensity = playIntensity
        store.characterSet = characterSet
        store.soundEnabled = soundEnabled
        store.musicEnabled = musicEnabled
        store.maxVolume = maxVolume
        store.sessionLimitMinutes = sessionLimitMinutes

        store.photoSource = photoSource
        store.selectedPhotoIDs = selectedPhotoIDs
        store.includedAlbumIDs = includedAlbumIDs
        store.excludedAlbumIDs = excludedAlbumIDs
        store.showVideos = showVideos
        store.slideshowInterval = slideshowInterval

        store.exitKeyCode = exitKeyCode
        store.exitModifiers = exitModifiers
        store.passwordEnabled = passwordEnabled

        if passwordEnabled {
            // A saved password stays valid when the fields are left empty.
            if password.isEmpty && confirmPassword.isEmpty && KeychainManager.hasPassword {
                passwordError = nil
                onLockNow?()
                return
            }
            guard !password.isEmpty else {
                passwordError = "Enter a password."
                return
            }
            guard password == confirmPassword else {
                passwordError = "The two passwords do not match."
                return
            }
            KeychainManager.savePassword(password)
        }

        passwordError = nil
        onLockNow?()
    }
}

/// A titled, bordered group with tight padding.
struct SettingsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
    }
}

/// Sizes the Settings window from inside SwiftUI: an ideal content size on
/// first appearance, a minimum below which the page would clip, and a
/// resizable frame.
struct WindowConfigurator: NSViewRepresentable {
    let contentSize: NSSize
    let minSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { apply(to: view, context: context) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { apply(to: nsView, context: context) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var configured = false
    }

    private func apply(to view: NSView, context: Context) {
        guard !context.coordinator.configured, let window = view.window else { return }
        context.coordinator.configured = true
        window.styleMask.insert(.resizable)
        window.contentMinSize = minSize
        window.setContentSize(contentSize)
        window.center()
    }
}
