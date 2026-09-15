import AVFoundation
import AppKit
import Photos

/// Which part of the photo library to show.
enum PhotoSource: String, CaseIterable, Identifiable {
    case recents = "Recents"
    case favorites = "Favorites"
    case selectedPhotos = "Chosen Photos"
    case includedAlbums = "Chosen Albums"
    case allExceptAlbums = "All Except Albums"

    var id: String { rawValue }

    var blurb: String {
        switch self {
        case .recents: return "Everything in the library"
        case .favorites: return "Only photos marked as favorites"
        case .selectedPhotos: return "Only photos you hand-pick"
        case .includedAlbums: return "Only albums you select"
        case .allExceptAlbums: return "Everything except albums you exclude"
        }
    }
}

struct PhotoAlbum: Identifiable {
    let id: String
    let title: String
    let count: Int
}

/// One displayable item from the library.
struct PhotoItem: Identifiable {
    let asset: PHAsset
    var id: String { asset.localIdentifier }
    var isVideo: Bool { asset.mediaType == .video }
}

/// Display-only access to the Photos library.
///
/// Safety is structural: this service only ever fetches and renders
/// images and videos. The app contains no PhotoKit mutation calls and no
/// share, edit, or delete UI anywhere.
@MainActor
final class PhotoLibraryService: ObservableObject {
    enum State {
        case loading
        case denied
        case empty
        case ready
    }

    @Published var state: State = .loading
    @Published var items: [PhotoItem] = []

    private var imageManager: PHCachingImageManager?

    /// Request access (when needed) and load a shuffled item list per the
    /// parent's settings.
    func prepare() async {
        var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        guard status == .authorized || status == .limited else {
            state = .denied
            return
        }
        imageManager = PHCachingImageManager()
        loadAssets()
    }

    /// True when access was already granted, so a session can show photos
    /// with no permission prompt in front of a child.
    nonisolated static var accessAlreadyGranted: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    /// Images always; videos only when the parent allows them.
    nonisolated static func mediaPredicate(includeVideos: Bool) -> NSPredicate {
        if includeVideos {
            return NSPredicate(
                format: "mediaType == %d OR mediaType == %d",
                PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue
            )
        }
        return NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
    }

    private func loadAssets() {
        let settings = SettingsStore.shared
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = Self.mediaPredicate(includeVideos: settings.showVideos)

        var all: [PHAsset] = []

        switch settings.photoSource {
        case .recents:
            all = flatten(PHAsset.fetchAssets(with: options))

        case .favorites:
            options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                Self.mediaPredicate(includeVideos: settings.showVideos),
                NSPredicate(format: "favorite == YES"),
            ])
            all = flatten(PHAsset.fetchAssets(with: options))

        case .selectedPhotos:
            all = flatten(PHAsset.fetchAssets(withLocalIdentifiers: settings.selectedPhotoIDs, options: options))

        case .includedAlbums:
            var seen = Set<String>()
            for albumID in settings.includedAlbumIDs {
                guard let collection = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [albumID], options: nil
                ).firstObject else { continue }
                for asset in flatten(PHAsset.fetchAssets(in: collection, options: options))
                where seen.insert(asset.localIdentifier).inserted {
                    all.append(asset)
                }
            }

        case .allExceptAlbums:
            var excluded = Set<String>()
            for albumID in settings.excludedAlbumIDs {
                guard let collection = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [albumID], options: nil
                ).firstObject else { continue }
                for asset in flatten(PHAsset.fetchAssets(in: collection, options: nil)) {
                    excluded.insert(asset.localIdentifier)
                }
            }
            all = flatten(PHAsset.fetchAssets(with: options)).filter { !excluded.contains($0.localIdentifier) }
        }

        all.shuffle()
        items = all.map { PhotoItem(asset: $0) }
        state = items.isEmpty ? .empty : .ready
    }

    private func flatten(_ fetch: PHFetchResult<PHAsset>) -> [PHAsset] {
        var result: [PHAsset] = []
        result.reserveCapacity(fetch.count)
        fetch.enumerateObjects { asset, _, _ in result.append(asset) }
        return result
    }

    /// Load one image (or a video's poster frame), sized for the screen.
    /// iCloud downloads allowed.
    func image(for item: PhotoItem, targetSize: CGSize) async -> NSImage? {
        guard let manager = imageManager else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        return await withCheckedContinuation { continuation in
            manager.requestImage(for: item.asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// A playable item for a video asset. The caller shows it in a bare
    /// AVPlayerLayer with no controls.
    func playerItem(for item: PhotoItem) async -> AVPlayerItem? {
        guard item.isVideo else { return nil }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestPlayerItem(forVideo: item.asset, options: options) { playerItem, _ in
                continuation.resume(returning: playerItem)
            }
        }
    }

    /// List the user's albums for the settings pickers. Call only after
    /// authorization.
    nonisolated static func listAlbums() -> [PhotoAlbum] {
        var albums: [PhotoAlbum] = []
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        collections.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            guard count > 0 else { return }
            albums.append(PhotoAlbum(id: collection.localIdentifier, title: collection.localizedTitle ?? "Untitled", count: count))
        }
        return albums.sorted { $0.count > $1.count }
    }
}

extension AVPlayer {
    /// A player set up the way the kid modes need it: volume capped by the
    /// parent's setting, no external playback.
    static func kidSafe(playerItem: AVPlayerItem) -> AVPlayer {
        let player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        player.volume = Float(SettingsStore.shared.maxVolume) * PlayStyle.current.volumeScale
        return player
    }
}
