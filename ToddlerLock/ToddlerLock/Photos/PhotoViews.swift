import AVFoundation
import AppKit
import Photos
import SwiftUI

// The two kid-safe photo modes and the parent-facing screens around them.
//
// Everything here is display only. There is no share, edit, export, or
// delete control, videos have no playback controls, and nothing leaves the
// screen. The views only read from PhotoLibraryService.

// MARK: - Root

/// Decides what the screen shows: photos, or a message for the parent.
struct PhotoModeRootView: View {
    let style: PlayModeType
    @ObservedObject var input: PhotoInput

    @StateObject private var library = PhotoLibraryService()

    /// True when the app does not have photo access yet. The mode shows a
    /// message instead of asking, because a locked screen cannot answer a
    /// system prompt.
    @State private var accessNeeded = false

    var body: some View {
        ZStack {
            Color.black
            content
        }
        .task {
            guard PhotoLibraryService.accessAlreadyGranted else {
                accessNeeded = true
                return
            }
            await library.prepare()
        }
    }

    @ViewBuilder
    private var content: some View {
        if accessNeeded {
            accessScreen
        } else {
            switch library.state {
            case .loading:
                PhotoLoadingView()
            case .denied:
                accessScreen
            case .empty:
                PhotoStatusView(
                    symbol: "photo.on.rectangle",
                    title: "No photos here yet",
                    detail: "This photo source is empty. Choose another source in Settings."
                )
            case .ready:
                if style == .explore {
                    ExploreView(library: library, input: input)
                } else {
                    SlideshowView(library: library, input: input)
                }
            }
        }
    }

    private var accessScreen: some View {
        PhotoStatusView(
            symbol: "eye.slash",
            title: "Photo access needed",
            detail: "Photo access is off for Toddler Mode. Turn it on in System Settings → Privacy & Security → Photos, then lock again."
        )
    }
}

// MARK: - Slideshow

/// Shuffled photos that change on their own, with a crossfade and a slow
/// zoom. Videos play through with no controls, up to 30 seconds. Any key or
/// click moves to the next item at once.
struct SlideshowView: View {
    @ObservedObject var library: PhotoLibraryService
    @ObservedObject var input: PhotoInput

    private enum Media {
        case image(NSImage)
        case video(AVPlayer)
    }

    /// Longest a single video holds the screen before the show moves on.
    private static let maxVideoSeconds: Double = 30
    private static let fadeSeconds: Double = 0.8

    @State private var index = 0
    @State private var current: Media?
    @State private var zoomIn = false
    @State private var generation = 0
    @State private var advanceTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                switch current {
                case .image(let image):
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(zoomIn ? 1.12 : 1.0)
                        .clipped()
                        .id(generation)
                        .transition(.opacity.animation(.easeInOut(duration: Self.fadeSeconds)))
                case .video(let player):
                    BareVideoView(player: player)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .id(generation)
                        .transition(.opacity.animation(.easeInOut(duration: Self.fadeSeconds)))
                case nil:
                    PhotoLoadingView()
                }

                PhotoInputCatcher(
                    onClick: { _ in advance(size: geo.size) },
                    onScroll: { input.scroll(deltaY: $0) }
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                advance(size: geo.size)
            }
            .onReceive(input.commands) { _ in
                advance(size: geo.size)
            }
            .onChange(of: input.isActive) { active in
                if !active { stop() }
            }
            .onDisappear {
                stop()
            }
        }
    }

    // MARK: Playback

    private func stop() {
        advanceTask?.cancel()
        advanceTask = nil
        releaseVideo()
    }

    private func releaseVideo() {
        if case .video(let player) = current {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
    }

    /// Show the next item, then schedule the one after it.
    private func advance(size: CGSize) {
        advanceTask?.cancel()
        releaseVideo()
        advanceTask = Task {
            guard !library.items.isEmpty else { return }

            let item = library.items[index % library.items.count]
            index += 1

            let holdSeconds: Double
            if item.isVideo, let playerItem = await library.playerItem(for: item) {
                guard !Task.isCancelled else { return }
                let duration = (try? await playerItem.asset.load(.duration).seconds) ?? 0
                guard !Task.isCancelled else { return }
                let player = AVPlayer.kidSafe(playerItem: playerItem)
                withAnimation(.easeInOut(duration: Self.fadeSeconds)) {
                    current = .video(player)
                    generation += 1
                }
                player.play()
                holdSeconds = min(max(duration.isFinite ? duration : 0, 1), Self.maxVideoSeconds)
            } else {
                let image = await library.image(for: item, targetSize: size.inPixels)
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: Self.fadeSeconds)) {
                    if let image { current = .image(image) }
                    generation += 1
                }

                // A slow zoom over the photo's time on screen.
                zoomIn = false
                let interval = SettingsStore.shared.slideshowInterval
                withAnimation(.linear(duration: interval + 1.0)) {
                    zoomIn = true
                }
                holdSeconds = interval
            }

            try? await Task.sleep(nanoseconds: UInt64(holdSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            advance(size: size)
        }
    }
}

// MARK: - Explore

/// One photo at a time, full screen. Arrow keys, clicks, and scrolls move
/// through the photos, and the list wraps around at both ends.
struct ExploreView: View {
    @ObservedObject var library: PhotoLibraryService
    @ObservedObject var input: PhotoInput

    /// How long the arrow hints stay on screen.
    private static let hintSeconds: Double = 4

    @State private var index = 0
    @State private var hintVisible = true
    @State private var hintTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                if library.items.indices.contains(index) {
                    ExplorePageView(
                        item: library.items[index],
                        library: library,
                        containerSize: geo.size,
                        isActive: input.isActive
                    )
                    .id(index)
                    .transition(.opacity.animation(.easeInOut(duration: 0.35)))
                }

                hints

                PhotoInputCatcher(
                    onClick: { isRightHalf in move(isRightHalf ? 1 : -1) },
                    onScroll: { input.scroll(deltaY: $0) }
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onReceive(input.commands) { command in
                move(command == .next ? 1 : -1)
            }
            .onAppear {
                fadeHints()
            }
            .onDisappear {
                hintTask?.cancel()
            }
        }
    }

    /// Soft chevrons that show which way to go. They fade on the first move
    /// and after a few seconds.
    private var hints: some View {
        HStack {
            Image(systemName: "chevron.left")
            Spacer()
            Image(systemName: "chevron.right")
        }
        .font(.system(size: 54, weight: .thin))
        .foregroundColor(Color.white.opacity(0.35))
        .shadow(color: Color.black.opacity(0.6), radius: 8)
        .padding(.horizontal, 44)
        .opacity(hintVisible ? 1 : 0)
        .allowsHitTesting(false)
    }

    private func move(_ step: Int) {
        let count = library.items.count
        guard count > 0 else { return }
        hintTask?.cancel()
        withAnimation(.easeInOut(duration: 0.35)) {
            index = ((index + step) % count + count) % count
            hintVisible = false
        }
    }

    private func fadeHints() {
        hintTask?.cancel()
        hintTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(Self.hintSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1.5)) {
                hintVisible = false
            }
        }
    }
}

/// One full-screen item: a photo, or a video that loops with no controls.
struct ExplorePageView: View {
    let item: PhotoItem
    let library: PhotoLibraryService
    let containerSize: CGSize
    let isActive: Bool

    @State private var image: NSImage?
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black
            if let player {
                BareVideoView(player: player)
            } else if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                PhotoLoadingView()
            }
        }
        .task {
            guard image == nil, player == nil else { return }
            if item.isVideo, let playerItem = await library.playerItem(for: item) {
                let newPlayer = AVPlayer.kidSafe(playerItem: playerItem)
                player = newPlayer
                newPlayer.play()
                return
            }
            image = await library.image(for: item, targetSize: containerSize.inPixels)
        }
        .onDisappear {
            release()
        }
        .onChange(of: isActive) { active in
            if !active { release() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { note in
            // Loop while this item is on screen.
            guard isActive, let player, (note.object as? AVPlayerItem) === player.currentItem else { return }
            player.seek(to: .zero)
            player.play()
        }
    }

    private func release() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }
}

// MARK: - Video surface

/// A video surface with nothing on it: no scrubber, no volume slider, no
/// AirPlay, no menu. Both photo modes use it, so a video is as inert as a
/// photo.
struct BareVideoView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateNSView(_ nsView: PlayerLayerView, context: Context) {
        if nsView.playerLayer.player !== player {
            nsView.playerLayer.player = player
        }
    }

    static func dismantleNSView(_ nsView: PlayerLayerView, coordinator: ()) {
        nsView.playerLayer.player?.pause()
        nsView.playerLayer.player = nil
    }

    /// A plain layer-backed view whose layer is an AVPlayerLayer.
    final class PlayerLayerView: NSView {
        let playerLayer = AVPlayerLayer()

        init() {
            super.init(frame: .zero)
            wantsLayer = true
            layerContentsRedrawPolicy = .duringViewResize
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not supported") }

        override func makeBackingLayer() -> CALayer {
            playerLayer
        }

        /// Clicks belong to the mode, not to the video.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}

// MARK: - Clicks and scrolls

/// A transparent top layer that reports clicks and scrolls. It works the
/// same for a real mouse in the preview window and for the events the lock
/// screen synthesizes at the virtual pointer.
struct PhotoInputCatcher: NSViewRepresentable {
    /// True when the click landed on the right half of the screen.
    let onClick: (Bool) -> Void
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.onClick = onClick
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: CatcherView, context: Context) {
        nsView.onClick = onClick
        nsView.onScroll = onScroll
    }

    final class CatcherView: NSView {
        var onClick: ((Bool) -> Void)?
        var onScroll: ((CGFloat) -> Void)?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            onClick?(point.x >= bounds.midX)
        }

        override func scrollWheel(with event: NSEvent) {
            onScroll?(event.scrollingDeltaY)
        }
    }
}

// MARK: - Parent-facing screens

/// White on black, centered, with nothing to press. These screens appear
/// before any photo does, so they speak to the grown-up.
struct PhotoStatusView: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .light))
                    .foregroundColor(Color.white.opacity(0.7))
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)
                Text("Grown-ups: use the exit shortcut to leave")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.top, 12)
            }
            .padding(40)
        }
    }
}

/// Shown while the first photo loads.
struct PhotoLoadingView: View {
    var body: some View {
        ZStack {
            Color.black
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(.white)
        }
    }
}

// MARK: - Helpers

private extension CGSize {
    /// The size in pixels, so photos load sharp on a retina display.
    var inPixels: CGSize {
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        return CGSize(width: width * scale, height: height * scale)
    }
}
