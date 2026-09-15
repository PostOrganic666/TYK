import SwiftUI
import AppKit
import CoreGraphics
import Photos
import AVFoundation

// MARK: - Play

/// The Play tab: mode grid, play style, letters, sound, volume, and timer.
struct PlaySettingsSection: View {
    @Binding var selectedMode: PlayModeType
    @Binding var playIntensity: PlayIntensity
    @Binding var characterSet: LetterCharacterSet
    @Binding var soundEnabled: Bool
    @Binding var musicEnabled: Bool
    @Binding var maxVolume: Double
    @Binding var sessionLimitMinutes: Int

    private let modeColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    private let timerOptions = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        Form {
            Section("Play Mode") {
                LazyVGrid(columns: modeColumns, spacing: 12) {
                    ForEach(PlayModeType.allCases, id: \.self) { mode in
                        ModeCard(mode: mode, isSelected: selectedMode == mode) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Play Style") {
                Picker("Style", selection: $playIntensity) {
                    ForEach(PlayIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text(playIntensity.blurb)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Letters & Sound") {
                Picker("Letters", selection: $characterSet) {
                    ForEach(LetterCharacterSet.allCases, id: \.self) { cs in
                        Text(cs.rawValue).tag(cs)
                    }
                }
                Text(characterSet.characters.prefix(6).joined(separator: " "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Toggle("Sound effects", isOn: $soundEnabled)
                Toggle("Background music", isOn: $musicEnabled)
            }

            Section("Max Volume") {
                HStack {
                    Slider(value: $maxVolume, in: 0.1...1.0, step: 0.1) { editing in
                        if !editing {
                            SoundManager.shared.playTouchTone(normalizedX: 0.5)
                        }
                    }
                    Text("\(Int((maxVolume * 100).rounded()))%")
                        .font(.callout.monospacedDigit())
                        .frame(width: 46, alignment: .trailing)
                }
            }

            Section("Play Timer") {
                Picker("Timer", selection: $sessionLimitMinutes) {
                    Text("Off").tag(0)
                    ForEach(timerOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                Text("When time ends, the screen changes to a calm break scene. The exit shortcut still works.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// One selectable mode card in the Play grid.
private struct ModeCard: View {
    let mode: PlayModeType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mode.emoji)
                    .font(.system(size: 26))
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text(mode.blurb)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Photos

/// The Photos tab: access status for Photos and Camera, source picker,
/// and the video/slideshow options. Chosen-photo and album pickers are
/// implemented by AlbumMultiSelectView / PhotoPickerButton and embedded
/// here as-is.
struct PhotosSettingsSection: View {
    @Binding var photoSource: PhotoSource
    @Binding var showVideos: Bool
    @Binding var slideshowInterval: Double

    @State private var photosAllowed = PhotoLibraryService.accessAlreadyGranted
    @State private var cameraAllowed = PlayCameraController.accessAlreadyGranted
    @State private var albumSheetKind: AlbumSheetKind?

    private enum AlbumSheetKind: Identifiable {
        case include
        case exclude
        var id: Self { self }
    }

    private var selectedPhotoIDsBinding: Binding<[String]> {
        Binding(
            get: { SettingsStore.shared.selectedPhotoIDs },
            set: { SettingsStore.shared.selectedPhotoIDs = $0 }
        )
    }

    private var includedAlbumIDsBinding: Binding<[String]> {
        Binding(
            get: { SettingsStore.shared.includedAlbumIDs },
            set: { SettingsStore.shared.includedAlbumIDs = $0 }
        )
    }

    private var excludedAlbumIDsBinding: Binding<[String]> {
        Binding(
            get: { SettingsStore.shared.excludedAlbumIDs },
            set: { SettingsStore.shared.excludedAlbumIDs = $0 }
        )
    }

    var body: some View {
        Form {
            Section("Photos Access") {
                HStack {
                    statusIcon(photosAllowed)
                    Text(photosAllowed ? "Photos access: allowed" : "Photos access: not allowed")
                    Spacer()
                    if !photosAllowed {
                        Button("Allow Photos Access…") { requestPhotosAccess() }
                    }
                }
                Text("The permission prompt appears only here, never during play.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Camera Access") {
                HStack {
                    statusIcon(cameraAllowed)
                    Text(cameraAllowed ? "Camera access: allowed" : "Camera access: not allowed")
                    Spacer()
                    if !cameraAllowed {
                        Button("Allow Camera Access…") { requestCameraAccess() }
                    }
                }
            }

            Section("Photo Source") {
                Picker("Source", selection: $photoSource) {
                    ForEach(PhotoSource.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                Text(photoSource.blurb)
                    .font(.caption)
                    .foregroundColor(.secondary)

                switch photoSource {
                case .selectedPhotos:
                    PhotoPickerButton(selectedIDs: selectedPhotoIDsBinding)
                case .includedAlbums:
                    Button("Select Albums… (\(SettingsStore.shared.includedAlbumIDs.count) chosen)") {
                        albumSheetKind = .include
                    }
                case .allExceptAlbums:
                    Button("Exclude Albums… (\(SettingsStore.shared.excludedAlbumIDs.count) chosen)") {
                        albumSheetKind = .exclude
                    }
                case .recents, .favorites:
                    EmptyView()
                }
            }

            Section("Videos") {
                Toggle("Include videos", isOn: $showVideos)
                Text("Videos play with no controls. Slideshow plays each one for up to 30 seconds. Explore loops it until the kid moves on.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Slideshow Speed") {
                HStack {
                    Slider(value: $slideshowInterval, in: 3...15, step: 1)
                    Text("\(Int(slideshowInterval))s")
                        .font(.callout.monospacedDigit())
                        .frame(width: 34, alignment: .trailing)
                }
            }

            Section {
                Text("Photo access is display-only. The app has no share, edit, or delete functions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .sheet(item: $albumSheetKind) { kind in
            albumSheet(for: kind)
        }
    }

    @ViewBuilder
    private func statusIcon(_ allowed: Bool) -> some View {
        Image(systemName: allowed ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundColor(allowed ? .green : .secondary)
    }

    private func requestPhotosAccess() {
        Task {
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run { photosAllowed = PhotoLibraryService.accessAlreadyGranted }
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                cameraAllowed = PlayCameraController.accessAlreadyGranted
            }
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
                        selection: includedAlbumIDsBinding
                    )
                case .exclude:
                    AlbumMultiSelectView(
                        title: "Excluded Albums",
                        explanation: "Kids see the whole library except photos in the checked albums.",
                        selection: excludedAlbumIDsBinding
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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

// MARK: - Exit

/// The Exit tab: exit shortcut recorder and password protection.
struct ExitSettingsSection: View {
    @Binding var exitKeyCode: UInt16
    @Binding var exitModifiers: CGEventFlags
    @Binding var passwordEnabled: Bool
    @Binding var password: String
    @Binding var confirmPassword: String
    let showPasswordError: Bool
    let passwordErrorMessage: String

    var body: some View {
        Form {
            Section("Exit Shortcut") {
                ShortcutRecorderView(keyCode: $exitKeyCode, modifiers: $exitModifiers)
                    .frame(height: 30)
                Text("Requires 2+ modifiers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Password") {
                Toggle("Require a password to unlock", isOn: $passwordEnabled)
                if passwordEnabled {
                    SecureField("Password", text: $password)
                    SecureField("Confirm password", text: $confirmPassword)
                    if showPasswordError {
                        Text(passwordErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Section {
                Text("Emergency unlock (\(BackdoorShortcut.displayShortcut)) always works, even if you forget your shortcut or password.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - About

/// The About tab: version, companion-app note, and update check.
struct AboutSettingsSection: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Toddler Mode")
                            .font(.title3.bold())
                        Text("Version \(version)")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                Text("Companion to Toddler Mode for iPhone.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Check for Updates…") {
                    UpdateManager.shared.checkForUpdates()
                }
            }
        }
        .formStyle(.grouped)
    }
}
