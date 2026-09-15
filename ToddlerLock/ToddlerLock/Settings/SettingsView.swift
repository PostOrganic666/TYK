import SwiftUI
import AppKit
import Combine
import CoreGraphics

/// The Settings window the parent uses before locking.
///
/// One scrolling page. The mode grid sits at the top and decides what
/// appears below it: letters for Free Play and Character, photo settings
/// for Slideshow and Explore, access rows for the modes that use the
/// photo library or the camera. Settings that apply to every mode (play
/// style, sound, timer, exit) stay in place.
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
    @State private var showPasswordError: Bool = false
    @State private var passwordErrorMessage: String = ""

    // Access
    @State private var photosAllowed: Bool = PhotoLibraryService.accessAlreadyGranted
    @State private var cameraAllowed: Bool = PlayCameraController.accessAlreadyGranted

    var onLockNow: (() -> Void)?

    private let exitSectionID = "exit"

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                Form {
                    ModeGridSection(selectedMode: $selectedMode)

                    if selectedMode.usesLetters {
                        LettersSection(characterSet: $characterSet)
                    }

                    if selectedMode.usesPhotoLibrary {
                        PhotosSection(
                            selectedMode: selectedMode,
                            photosAllowed: $photosAllowed,
                            photoSource: $photoSource,
                            selectedPhotoIDs: $selectedPhotoIDs,
                            includedAlbumIDs: $includedAlbumIDs,
                            excludedAlbumIDs: $excludedAlbumIDs,
                            showVideos: $showVideos,
                            slideshowInterval: $slideshowInterval
                        )
                    } else if selectedMode.showsPhotosAccess {
                        PhotosAccessOnlySection(photosAllowed: $photosAllowed)
                    }

                    if selectedMode.showsCameraAccess {
                        CameraSection(selectedMode: selectedMode, cameraAllowed: $cameraAllowed)
                    }

                    PlayStyleSection(playIntensity: $playIntensity)

                    SoundSection(
                        soundEnabled: $soundEnabled,
                        musicEnabled: $musicEnabled,
                        maxVolume: $maxVolume
                    )

                    PlayTimerSection(sessionLimitMinutes: $sessionLimitMinutes)

                    ExitSection(
                        exitKeyCode: $exitKeyCode,
                        exitModifiers: $exitModifiers,
                        passwordEnabled: $passwordEnabled,
                        password: $password,
                        confirmPassword: $confirmPassword,
                        showPasswordError: showPasswordError,
                        passwordErrorMessage: passwordErrorMessage
                    )
                    .id(exitSectionID)

                    AboutSection()
                }
                .formStyle(.grouped)
                .onReceive(scrollToExit) { _ in
                    withAnimation { proxy.scrollTo(exitSectionID, anchor: .center) }
                }
            }

            Divider()
            bottomBar
        }
        .frame(minWidth: 680, minHeight: 560)
        .background(WindowConfigurator(contentSize: NSSize(width: 780, height: 800),
                                       minSize: NSSize(width: 680, height: 560)))
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshAccess()
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let need = pendingAccess {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text(need.message)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button(need.buttonTitle, action: need.action)
                }
                .padding(.horizontal, 24)
                .transition(.opacity)
            }

            Button(action: lockNow) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text("Lock Now: \(selectedMode.rawValue)")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .help("Start \(selectedMode.rawValue) and lock the screen.")

            #if DEBUG
            Text("Debug build. The lock opens on its own after 60 seconds.")
                .font(.caption2)
                .foregroundColor(.secondary)
            #endif
        }
        .padding(.vertical, 14)
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

    // MARK: - Access refresh

    private func refreshAccess() {
        photosAllowed = PhotoLibraryService.accessAlreadyGranted
        cameraAllowed = PlayCameraController.accessAlreadyGranted
    }

    /// Fires when the password check fails, so the page scrolls to Exit.
    private var scrollToExit: AnyPublisher<Void, Never> {
        SettingsScrollSignal.shared.toExit.eraseToAnyPublisher()
    }

    // MARK: - Lock

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
        SettingsStore.shared.selectedPhotoIDs = selectedPhotoIDs
        SettingsStore.shared.includedAlbumIDs = includedAlbumIDs
        SettingsStore.shared.excludedAlbumIDs = excludedAlbumIDs
        SettingsStore.shared.showVideos = showVideos
        SettingsStore.shared.slideshowInterval = slideshowInterval

        // Exit
        SettingsStore.shared.exitKeyCode = exitKeyCode
        SettingsStore.shared.exitModifiers = exitModifiers
        SettingsStore.shared.passwordEnabled = passwordEnabled

        if passwordEnabled {
            guard !password.isEmpty else {
                failPassword("Enter a password.")
                return
            }
            guard password == confirmPassword else {
                failPassword("The two passwords do not match.")
                return
            }
            KeychainManager.savePassword(password)
        }

        showPasswordError = false
        onLockNow?()
    }

    private func failPassword(_ message: String) {
        passwordErrorMessage = message
        showPasswordError = true
        SettingsScrollSignal.shared.toExit.send(())
    }
}

/// Carries the one scroll request the page needs.
final class SettingsScrollSignal {
    static let shared = SettingsScrollSignal()
    let toExit = PassthroughSubject<Void, Never>()
    private init() {}
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
