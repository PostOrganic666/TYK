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

// MARK: - Mode grid

/// The eight mode cards, compact: emoji and name, blurb on the selected one.
struct ModeGrid: View {
    @Binding var selectedMode: PlayModeType

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(PlayModeType.allCases, id: \.self) { mode in
                    ModeCard(mode: mode, isSelected: selectedMode == mode) {
                        withAnimation(.easeInOut(duration: 0.18)) { selectedMode = mode }
                    }
                }
            }
            Text("\(selectedMode.blurb). \(selectedMode.setupHint)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(nil, value: selectedMode)
        }
    }
}

private struct ModeCard: View {
    let mode: PlayModeType
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(mode.emoji).font(.system(size: 22))
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(fillColor))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(mode.rawValue). \(mode.blurb)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .help(mode.blurb)
    }

    private var fillColor: Color {
        if isSelected { return Color.accentColor.opacity(0.16) }
        return Color.primary.opacity(isHovering ? 0.10 : 0.05)
    }
}

/// A label on the left, a control on the right, one line.
struct SettingRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(width: 96, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Play (every mode)

struct PlayPanel: View {
    @Binding var playIntensity: PlayIntensity
    @Binding var soundEnabled: Bool
    @Binding var musicEnabled: Bool
    @Binding var maxVolume: Double
    @Binding var sessionLimitMinutes: Int

    private let timerOptions = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            SettingRow(label: "Style") {
                Picker("Style", selection: $playIntensity) {
                    ForEach(PlayIntensity.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 230)
                .help(playIntensity.blurb)
            }
            Text(playIntensity.blurb)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 106)

            SettingRow(label: "Sound") {
                Toggle("Effects", isOn: $soundEnabled).toggleStyle(.checkbox)
                Toggle("Music", isOn: $musicEnabled).toggleStyle(.checkbox)
            }
            SettingRow(label: "Max volume") {
                Slider(value: $maxVolume, in: 0.1...1.0, step: 0.1) { editing in
                    if !editing { previewVolume() }
                }
                .frame(maxWidth: 170)
                Text("\(Int((maxVolume * 100).rounded()))%")
                    .font(.callout.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 38, alignment: .trailing)
            }
            .help("Caps every sound and video the app plays.")
            SettingRow(label: "Break after") {
                Picker("Break after", selection: $sessionLimitMinutes) {
                    Text("Off").tag(0)
                    ForEach(timerOptions, id: \.self) { Text("\($0) min").tag($0) }
                }
                .labelsHidden()
                .frame(maxWidth: 110)
                .help("When the time ends, the screen changes to a calm break scene.")
            }
        }
    }

    private func previewVolume() {
        guard soundEnabled else { return }
        SoundManager.shared.maxVolume = Float(maxVolume)
        SoundManager.shared.playTouchTone(normalizedX: 0.5)
    }
}

// MARK: - For this mode

/// The panel that changes with the selected mode.
struct ModePanel: View {
    let selectedMode: PlayModeType
    @Binding var characterSet: LetterCharacterSet
    @Binding var photosAllowed: Bool
    @Binding var cameraAllowed: Bool
    @Binding var photoSource: PhotoSource
    @Binding var selectedPhotoIDs: [String]
    @Binding var includedAlbumIDs: [String]
    @Binding var excludedAlbumIDs: [String]
    @Binding var showVideos: Bool
    @Binding var slideshowInterval: Double

    @State private var albumSheetKind: AlbumSheetKind?

    enum AlbumSheetKind: Identifiable {
        case include, exclude
        var id: Self { self }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if selectedMode.usesLetters {
                SettingRow(label: "Characters") {
                    Picker("Characters", selection: $characterSet) {
                        ForEach(LetterCharacterSet.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 150)
                }
                Text(characterSet.characters.prefix(10).joined(separator: " "))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.leading, 106)
            }

            if selectedMode.usesPhotoLibrary {
                AccessRow(granted: photosAllowed, title: "Photos access", buttonTitle: "Allow Photos…",
                          showsButton: !selectedMode.requiresPhotosAccess) {
                    AccessRequester.requestPhotos { photosAllowed = $0 }
                }
                SettingRow(label: "Show") {
                    Picker("Show photos from", selection: $photoSource) {
                        ForEach(PhotoSource.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 170)
                    .help(photoSource.blurb)
                    sourceDetail
                }
                SettingRow(label: "Videos") {
                    Toggle("Include videos", isOn: $showVideos)
                        .toggleStyle(.checkbox)
                        .help("Videos play with no controls. Slideshow plays each one for up to 30 seconds. Explore loops it until the kid moves on.")
                }
                if selectedMode == .slideshow {
                    SettingRow(label: "Speed") {
                        Slider(value: $slideshowInterval, in: 3...15, step: 1)
                            .frame(maxWidth: 150)
                        Text("\(Int(slideshowInterval))s per photo")
                            .font(.callout.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                Text("The app shows photos only. It has no share, edit, or delete controls.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if selectedMode.showsPhotosAccess {
                AccessRow(granted: photosAllowed, title: "Photos access", buttonTitle: "Allow Photos…") {
                    AccessRequester.requestPhotos { photosAllowed = $0 }
                }
                Text("The pretend Mac has a photo app. With access it shows your photos. Without access it shows an emoji album.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if selectedMode.showsCameraAccess {
                AccessRow(granted: cameraAllowed, title: "Camera access", buttonTitle: "Allow Camera…",
                          showsButton: !selectedMode.requiresCameraAccess) {
                    AccessRequester.requestCamera { cameraAllowed = $0 }
                }
                Text(selectedMode == .playComputer
                     ? "The pretend Mac has a camera app. It shows the live view and saves nothing."
                     : "The app saves no photos and no video.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !selectedMode.usesLetters && !selectedMode.showsPhotosAccess && !selectedMode.showsCameraAccess {
                Text("No extra setup. Pick a style and lock.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(item: $albumSheetKind) { kind in albumSheet(for: kind) }
    }

    @ViewBuilder
    private var sourceDetail: some View {
        switch photoSource {
        case .selectedPhotos:
            PhotoPickerButton(selectedIDs: $selectedPhotoIDs)
        case .includedAlbums:
            Button("Albums… (\(includedAlbumIDs.count))") { albumSheetKind = .include }
        case .allExceptAlbums:
            Button("Exclude… (\(excludedAlbumIDs.count))") { albumSheetKind = .exclude }
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
                    AlbumMultiSelectView(title: "Chosen Albums",
                                         explanation: "Kids see only photos from the checked albums.",
                                         selection: $includedAlbumIDs)
                case .exclude:
                    AlbumMultiSelectView(title: "Excluded Albums",
                                         explanation: "Kids see the whole library except photos in the checked albums.",
                                         selection: $excludedAlbumIDs)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            Divider()
            HStack {
                Spacer()
                Button("Done") { albumSheetKind = nil }.keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 420, height: 520)
    }
}

// MARK: - Exit (every mode)

struct ExitPanel: View {
    @Binding var exitKeyCode: UInt16
    @Binding var exitModifiers: CGEventFlags
    @Binding var passwordEnabled: Bool
    @Binding var password: String
    @Binding var confirmPassword: String
    let passwordError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 14) {
                SettingRow(label: "Shortcut") {
                    ShortcutRecorderView(keyCode: $exitKeyCode, modifiers: $exitModifiers)
                        .frame(width: 160, height: 26)
                        .help("Hold two or more modifier keys, then press one key.")
                }
                .frame(maxWidth: 300)

                Toggle("Ask for a password", isOn: $passwordEnabled)
                    .toggleStyle(.checkbox)
                if passwordEnabled {
                    SecureField(KeychainManager.hasPassword ? "New password" : "Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                    SecureField("Confirm", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 12) {
                Text("The emergency unlock \(BackdoorShortcut.displayShortcut) always works.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let passwordError {
                    Text(passwordError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
