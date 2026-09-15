import AppKit
import Photos
import PhotosUI
import SwiftUI

// Settings components for the Photos section. These run in Settings, where
// a grown-up can answer a system prompt, so they may ask for photo access.
// The play modes never do.

/// Multi-select album list used for both Chosen Albums (include) and All
/// Except Albums (exclude). Binds to the SettingsStore id list.
struct AlbumMultiSelectView: View {
    let title: String
    let explanation: String
    @Binding var selection: [String]

    @State private var albums: [PhotoAlbum] = []
    @State private var accessDenied = false
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            content

            Text(explanation)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .task {
            await load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if !loaded {
            HStack {
                ProgressView().controlSize(.small)
                Text("Loading albums…")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        } else if accessDenied {
            Text("Photo access is off. Turn it on in System Settings → Privacy & Security → Photos.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 6)
        } else if albums.isEmpty {
            Text("No albums with photos found.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
        } else {
            List {
                ForEach(albums) { album in
                    row(for: album)
                }
            }
            .listStyle(.plain)
            .frame(height: 150)
            .cornerRadius(6)
        }
    }

    private func row(for album: PhotoAlbum) -> some View {
        let isOn = selection.contains(album.id)
        return Button {
            toggle(album.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .accentColor : .secondary)
                Text(album.title)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(album.count) photos")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ id: String) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else {
            selection.append(id)
        }
    }

    private func load() async {
        guard !loaded else { return }
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard status == .authorized || status == .limited else {
            accessDenied = true
            loaded = true
            return
        }
        // Counting assets per album is slow, so keep it off the main thread.
        albums = await Task.detached(priority: .userInitiated) {
            PhotoLibraryService.listAlbums()
        }.value
        loaded = true
    }
}

/// Opens the system photo picker so a grown-up can hand-pick the photos
/// kids may see. The picker runs outside the app and hands back only the
/// picks.
struct PhotoPickerButton: View {
    @Binding var selectedIDs: [String]

    @StateObject private var presenter = PhotoPickerPresenter()
    @State private var accessDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button("Choose Photos…") {
                    Task { await present() }
                }
                Text("\(selectedIDs.count) chosen")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            if accessDenied {
                Text("Photo access is off. Turn it on in System Settings → Privacy & Security → Photos.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func present() async {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard status == .authorized || status == .limited else {
            accessDenied = true
            return
        }
        accessDenied = false
        presenter.present(preselected: selectedIDs) { ids in
            // An empty result with earlier picks means cancel. Keep them.
            if !ids.isEmpty || selectedIDs.isEmpty {
                selectedIDs = ids
            }
        }
    }
}

/// Runs PHPickerViewController as a sheet on the current window and reports
/// the picked asset identifiers.
final class PhotoPickerPresenter: NSObject, ObservableObject, PHPickerViewControllerDelegate {
    private var onFinish: (([String]) -> Void)?

    func present(preselected: [String], onFinish: @escaping ([String]) -> Void) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              let host = window.contentViewController else { return }

        self.onFinish = onFinish

        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = SettingsStore.shared.showVideos ? .any(of: [.images, .videos]) : .images
        config.selectionLimit = 0
        config.preselectedAssetIdentifiers = preselected

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        host.presentAsSheet(picker)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.presentingViewController?.dismiss(picker)
        let ids = results.compactMap(\.assetIdentifier)
        onFinish?(ids)
        onFinish = nil
    }
}
