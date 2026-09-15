import SwiftUI
import AppKit
import CoreGraphics
import Photos
import AVFoundation

// The Settings window is one scrolling page. The mode grid comes first and
// decides which sections below it appear. Everything in this file is a
// section (or a small part of one) used by SettingsView.

// MARK: - What each mode needs

extension PlayModeType {
    /// Free Play and Character draw the letters the parent picks.
    var usesLetters: Bool { self == .freePlay || self == .character }

    /// Slideshow and Explore need a photo library to show.
    var usesPhotoLibrary: Bool { isPhotoMode }

    /// Play Computer has a photo app, so it also uses photo access.
    var showsPhotosAccess: Bool { isPhotoMode || self == .playComputer }

    /// Camera mode and the camera app inside Play Computer.
    var showsCameraAccess: Bool { self == .camera || self == .playComputer }

    /// The mode cannot show its main content without this access.
    var requiresPhotosAccess: Bool { isPhotoMode }

    var requiresCameraAccess: Bool { self == .camera }

    /// One line under the mode grid. It says what the mode needs, so the
    /// parent knows why the sections below change.
    var setupHint: String {
        switch self {
        case .freePlay: return "Free Play shows letters. Pick the character set below."
        case .playComputer: return "Play Computer has a photo app and a camera app. Turn on access below."
        case .camera: return "Camera shows a live view with filters. It needs camera access."
        case .game: return "Game needs no extra setup."
        case .character: return "Character shows letters in speech bubbles. Pick the set below."
        case .chill: return "Chill needs no extra setup."
        case .slideshow: return "Slideshow needs your photos. Pick them below."
        case .explore: return "Explore needs your photos. Pick them below."
        }
    }
}

/// Explanatory text under a group. Left-aligned, like System Settings.
struct FooterText: View {
    private let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Mode grid

/// The eight mode cards. Picking one reveals the sections that mode uses.
struct ModeGridSection: View {
    @Binding var selectedMode: PlayModeType

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(PlayModeType.allCases, id: \.self) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedMode = mode
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("Play mode")
        } footer: {
            FooterText(selectedMode.setupHint)
        }
    }
}

/// One selectable mode card.
private struct ModeCard: View {
    let mode: PlayModeType
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(mode.emoji)
                    .font(.system(size: 28))
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                Text(mode.blurb)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(mode.rawValue). \(mode.blurb)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .help(mode.blurb)
    }

    private var fillColor: Color {
        if isSelected { return Color.accentColor.opacity(0.14) }
        return Color.primary.opacity(isHovering ? 0.09 : 0.05)
    }
}

// MARK: - Letters

/// Shown for Free Play and Character.
struct LettersSection: View {
    @Binding var characterSet: LetterCharacterSet

    var body: some View {
        Section {
            Picker("Characters", selection: $characterSet) {
                ForEach(LetterCharacterSet.allCases, id: \.self) { set in
                    Text(set.rawValue).tag(set)
                }
            }
            LabeledContent("Sample") {
                Text(characterSet.characters.prefix(8).joined(separator: " "))
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Letters")
        } footer: {
            FooterText("Every key press draws one of these characters.")
        }
    }
}

// MARK: - Access rows

/// One access row: a status line and, when access is off, the button that
/// asks for it.
struct AccessRow: View {
    let granted: Bool
    let title: String
    let buttonTitle: String
    /// False when the Lock Now bar already offers the same button.
    var showsButton: Bool = true
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(granted ? .green : .orange)
                .accessibilityHidden(true)
            Text(granted ? "\(title) is on" : "\(title) is off")
            Spacer(minLength: 8)
            if !granted && showsButton {
                Button(buttonTitle, action: action)
            }
        }
    }
}

/// Asks for the two kinds of access. Settings is the only place that asks.
enum AccessRequester {
    static func requestPhotos(_ completion: @escaping (Bool) -> Void) {
        Task {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            let granted = PhotoLibraryService.accessAlreadyGranted
            await MainActor.run { completion(granted) }
        }
    }

    static func requestCamera(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                completion(PlayCameraController.accessAlreadyGranted)
            }
        }
    }
}

// MARK: - Photos

/// Shown for Slideshow and Explore: access, source, videos, and speed.
struct PhotosSection: View {
    let selectedMode: PlayModeType
    @Binding var photosAllowed: Bool
    @Binding var photoSource: PhotoSource
    @Binding var selectedPhotoIDs: [String]
    @Binding var includedAlbumIDs: [String]
    @Binding var excludedAlbumIDs: [String]
    @Binding var showVideos: Bool
    @Binding var slideshowInterval: Double

    @State private var albumSheetKind: AlbumSheetKind?

    private enum AlbumSheetKind: Identifiable {
        case include
        case exclude
        var id: Self { self }
    }

    var body: some View {
        Section {
            AccessRow(
                granted: photosAllowed,
                title: "Photos access",
                buttonTitle: "Allow Photos…",
                showsButton: !selectedMode.requiresPhotosAccess
            ) {
                AccessRequester.requestPhotos { photosAllowed = $0 }
            }

            Picker("Show photos from", selection: $photoSource) {
                ForEach(PhotoSource.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            FooterText(photoSource.blurb)

            sourceDetail

            Toggle("Include videos", isOn: $showVideos)
            if showVideos {
                FooterText("Videos play with no controls. Slideshow plays each one for up to 30 seconds. Explore loops it until the kid moves on.")
            }

            if selectedMode == .slideshow {
                LabeledContent("Slideshow speed") {
                    HStack(spacing: 10) {
                        Slider(value: $slideshowInterval, in: 3...15, step: 1)
                            .frame(minWidth: 160)
                        Text("\(Int(slideshowInterval))s")
                            .font(.callout.monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
        } header: {
            Text("Photos")
        } footer: {
            FooterText("The app shows photos only. It has no share, edit, or delete controls.")
        }
        .sheet(item: $albumSheetKind) { kind in
            albumSheet(for: kind)
        }
    }

    @ViewBuilder
    private var sourceDetail: some View {
        switch photoSource {
        case .selectedPhotos:
            PhotoPickerButton(selectedIDs: $selectedPhotoIDs)
        case .includedAlbums:
            HStack(spacing: 8) {
                Button("Select Albums…") { albumSheetKind = .include }
                Text("\(includedAlbumIDs.count) chosen")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        case .allExceptAlbums:
            HStack(spacing: 8) {
                Button("Exclude Albums…") { albumSheetKind = .exclude }
                Text("\(excludedAlbumIDs.count) excluded")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        case .recents, .favorites:
            EmptyView()
        }
    }

    @ViewBuilder
    private func albumSheet(for kind: AlbumSheetKind) -> some View {
        VStack(spacing: 0) {
            Group {
                switch kind {
                case .include:
                    AlbumMultiSelectView(
                        title: "Chosen Albums",
                        explanation: "Kids see only photos from the checked albums.",
                        selection: $includedAlbumIDs
                    )
                case .exclude:
                    AlbumMultiSelectView(
                        title: "Excluded Albums",
                        explanation: "Kids see the whole library except photos in the checked albums.",
                        selection: $excludedAlbumIDs
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Divider()

            HStack {
                Spacer()
                Button("Done") { albumSheetKind = nil }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 420, height: 520)
    }
}

/// Photos access on its own, for Play Computer.
struct PhotosAccessOnlySection: View {
    @Binding var photosAllowed: Bool

    var body: some View {
        Section {
            AccessRow(
                granted: photosAllowed,
                title: "Photos access",
                buttonTitle: "Allow Photos…"
            ) {
                AccessRequester.requestPhotos { photosAllowed = $0 }
            }
        } header: {
            Text("Photos")
        } footer: {
            FooterText("The pretend Mac has a photo app. With access, it shows your own photos. Without access, it shows an emoji album.")
        }
    }
}

// MARK: - Camera

/// Shown for Camera and for Play Computer.
struct CameraSection: View {
    let selectedMode: PlayModeType
    @Binding var cameraAllowed: Bool

    var body: some View {
        Section {
            AccessRow(
                granted: cameraAllowed,
                title: "Camera access",
                buttonTitle: "Allow Camera…",
                showsButton: !selectedMode.requiresCameraAccess
            ) {
                AccessRequester.requestCamera { cameraAllowed = $0 }
            }
        } header: {
            Text("Camera")
        } footer: {
            FooterText(footerText)
        }
    }

    private var footerText: String {
        if selectedMode == .playComputer {
            return "The pretend Mac has a camera app. It shows the live view and saves nothing."
        }
        return "The app saves no photos and no video."
    }
}

// MARK: - Play style

struct PlayStyleSection: View {
    @Binding var playIntensity: PlayIntensity

    var body: some View {
        Section {
            Picker("Style", selection: $playIntensity) {
                ForEach(PlayIntensity.allCases) { intensity in
                    Text(intensity.rawValue).tag(intensity)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } header: {
            Text("Play style")
        } footer: {
            FooterText(playIntensity.blurb)
        }
    }
}

// MARK: - Sound

struct SoundSection: View {
    @Binding var soundEnabled: Bool
    @Binding var musicEnabled: Bool
    @Binding var maxVolume: Double

    var body: some View {
        Section {
            Toggle("Sound effects", isOn: $soundEnabled)
            Toggle("Background music", isOn: $musicEnabled)
            LabeledContent("Max volume") {
                HStack(spacing: 10) {
                    Slider(value: $maxVolume, in: 0.1...1.0, step: 0.1) { editing in
                        if !editing { previewVolume() }
                    }
                    .frame(minWidth: 160)
                    Text("\(Int((maxVolume * 100).rounded()))%")
                        .font(.callout.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        } header: {
            Text("Sound")
        } footer: {
            FooterText("Max volume caps every sound and video the app plays.")
        }
    }

    private func previewVolume() {
        guard soundEnabled else { return }
        SoundManager.shared.maxVolume = Float(maxVolume)
        SoundManager.shared.playTouchTone(normalizedX: 0.5)
    }
}

// MARK: - Play timer

struct PlayTimerSection: View {
    @Binding var sessionLimitMinutes: Int

    private let timerOptions = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        Section {
            Picker("Break after", selection: $sessionLimitMinutes) {
                Text("Off").tag(0)
                ForEach(timerOptions, id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
        } header: {
            Text("Play timer")
        } footer: {
            FooterText("When the time ends, the screen changes to a calm break scene. The exit shortcut still works.")
        }
    }
}

// MARK: - Exit

/// Exit shortcut and password. Always shown: every mode ends the same way.
struct ExitSection: View {
    @Binding var exitKeyCode: UInt16
    @Binding var exitModifiers: CGEventFlags
    @Binding var passwordEnabled: Bool
    @Binding var password: String
    @Binding var confirmPassword: String
    let showPasswordError: Bool
    let passwordErrorMessage: String

    var body: some View {
        Section {
            LabeledContent("Exit shortcut") {
                ShortcutRecorderView(keyCode: $exitKeyCode, modifiers: $exitModifiers)
                    .frame(width: 170, height: 30)
            }
            FooterText("Hold two or more modifier keys, then press one key.")

            Toggle("Ask for a password to unlock", isOn: $passwordEnabled)
            if passwordEnabled {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                SecureField("Confirm password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                if showPasswordError {
                    Text(passwordErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        } header: {
            Text("Exit")
        } footer: {
            FooterText("The emergency unlock \(BackdoorShortcut.displayShortcut) always works. Use it if you forget the shortcut or the password.")
        }
    }
}

// MARK: - About

struct AboutSection: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Toddler Mode")
                        .font(.headline)
                    Text("Version \(version)")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Text("Companion to Toddler Mode for iPhone.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                Button("Check for Updates…") {
                    UpdateManager.shared.checkForUpdates()
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("About")
        }
    }
}
