import AVFoundation
import CoreImage
import SwiftUI

/// The silly filters the child can cycle through. Each one is applied as
/// `previewLayer.filters`, a live Core Image compositing filter on the
/// preview layer. No frame is ever captured, rendered, or saved.
enum CameraFilter: Int, CaseIterable, Equatable {
    case none, sepia, comic, pixel, thermal, xray, rainbow, upsideDown, glow, invert

    var name: String {
        switch self {
        case .none: return "None"
        case .sepia: return "Sepia"
        case .comic: return "Comic Book"
        case .pixel: return "Pixel"
        case .thermal: return "Thermal"
        case .xray: return "X-Ray"
        case .rainbow: return "Rainbow"
        case .upsideDown: return "Upside Down"
        case .glow: return "Glow"
        case .invert: return "Invert"
        }
    }

    /// A fresh Core Image filter for this case, or nil when the effect
    /// isn't a Core Image filter (None, and Upside Down which is a plain
    /// view rotation).
    func makeCIFilter() -> CIFilter? {
        switch self {
        case .none, .upsideDown:
            return nil
        case .sepia:
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            return filter
        case .comic:
            return CIFilter(name: "CIComicEffect")
        case .pixel:
            let filter = CIFilter(name: "CIPixellate")
            filter?.setValue(24.0, forKey: kCIInputScaleKey)
            return filter
        case .thermal:
            return CIFilter(name: "CIThermal")
        case .xray:
            return CIFilter(name: "CIXRay")
        case .rainbow:
            let filter = CIFilter(name: "CIHueAdjust")
            filter?.setValue(0.0, forKey: kCIInputAngleKey)
            return filter
        case .glow:
            let filter = CIFilter(name: "CIBloom")
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            filter?.setValue(12.0, forKey: kCIInputRadiusKey)
            return filter
        case .invert:
            return CIFilter(name: "CIColorInvert")
        }
    }
}

/// The PHOTO / VIDEO / SILLY strip above the shutter. Purely cosmetic
/// except SILLY, which makes every shutter press also cycle the filter.
enum CameraStripMode: Int, CaseIterable, Equatable {
    case video, photo, silly

    var label: String {
        switch self {
        case .video: return "VIDEO"
        case .photo: return "PHOTO"
        case .silly: return "SILLY"
        }
    }
}

/// Full-screen camera play view: a mirrored live preview, a real-camera
/// control bar, silly filters, and a shutter that is pure theater — there
/// is nothing behind it that saves or sends a picture anywhere.
struct CameraPlayView: View {
    @ObservedObject var camera: PlayCameraController
    @ObservedObject var input: CameraModeInput

    @State private var mirrored = true
    @State private var filter: CameraFilter = .none
    @State private var liveCIFilter: CIFilter?
    @State private var rainbowTimer: Timer?
    @State private var stripMode: CameraStripMode = .photo

    @State private var shots = 0
    @State private var burstID = 0
    @State private var flashOpacity: Double = 0

    @State private var showFilterPill = false
    @State private var pillWorkItem: DispatchWorkItem?

    @State private var emojiOffset: CGFloat = -18

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.state {
            case .checking:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            case .running:
                CameraPreviewRepresentable(session: camera.session, mirrored: mirrored, filter: liveCIFilter)
                    .rotationEffect(.degrees(filter == .upsideDown ? 180 : 0))
                    .ignoresSafeArea()
                overlay
            case .noCamera:
                pretendViewfinder
                overlay
            case .denied:
                deniedView
            }
        }
        .onReceive(input.actions) { handle($0) }
        .onDisappear { rainbowTimer?.invalidate() }
    }

    /// Flash, shot burst, filter pill, and the control bar. Shown over
    /// both the real preview and the pretend viewfinder, so the mode
    /// still plays fully on a Mac with no camera.
    private var overlay: some View {
        ZStack {
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if burstID > 0 {
                ShotBurst()
                    .id(burstID)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                shotCounter
                    .padding(.top, 50)

                if showFilterPill {
                    filterPill
                        .padding(.top, 14)
                        .transition(.opacity)
                }

                Spacer()

                modeStrip
                    .padding(.bottom, 16)

                bottomBar
                    .padding(.bottom, 34)
            }
        }
    }

    // MARK: - Chrome

    private var shotCounter: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.fill")
            Text("\(shots)").monospacedDigit()
        }
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(.black.opacity(0.45)))
    }

    private var filterPill: some View {
        Text(filter.name)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(.black.opacity(0.55)))
    }

    private var modeStrip: some View {
        HStack(spacing: 28) {
            ForEach(CameraStripMode.allCases, id: \.self) { mode in
                Text(mode.label)
                    .foregroundStyle(mode == stripMode ? .yellow : .white.opacity(0.5))
                    .overlay(alignment: .bottom) {
                        if mode == stripMode {
                            Circle().fill(.yellow).frame(width: 5, height: 5).offset(y: 10)
                        }
                    }
            }
        }
        .font(.system(size: 15, weight: .heavy, design: .rounded))
    }

    private var bottomBar: some View {
        HStack {
            Button {
                cycleFilter(forward: true)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 22))
                    Text(filter.name)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(Circle().fill(.black.opacity(0.45)))
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: fireShutter) {
                ZStack {
                    Circle().stroke(.white, lineWidth: 6).frame(width: 92, height: 92)
                    Circle().fill(.white).frame(width: 76, height: 76)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                SoundManager.shared.playWhoosh()
                mirrored.toggle()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(.black.opacity(0.45)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }

    /// A Mac with no camera still gets the full mode: a playful stand-in
    /// so every button still does its thing.
    private var pretendViewfinder: some View {
        ZStack {
            LinearGradient(colors: [.purple, .indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                Text("📷")
                    .font(.system(size: 100))
                    .offset(y: emojiOffset)
                Text("Pretend viewfinder")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                emojiOffset = 18
            }
        }
    }

    private var deniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 46))
                .foregroundStyle(.white.opacity(0.6))
            Text("Camera access is off for Toddler Mode.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text("Turn it on in System Settings → Privacy & Security → Camera, then lock again.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Text("Grown-ups: use the exit shortcut to leave.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(40)
    }

    // MARK: - Actions

    private func handle(_ action: CameraModeInput.Action) {
        switch camera.state {
        case .denied, .checking:
            return
        case .running, .noCamera:
            break
        }
        switch action {
        case .shutter:
            fireShutter()
        case .cycleFilter(let forward):
            cycleFilter(forward: forward)
        case .selectFilter(let digit):
            jumpToFilter(digit)
        case .cycleStrip:
            cycleStrip()
        }
    }

    private func fireShutter() {
        shots += 1
        burstID += 1
        SoundManager.shared.playShutter()
        flashOpacity = 1
        withAnimation(.easeOut(duration: 0.4)) {
            flashOpacity = 0
        }
        if stripMode == .silly {
            cycleFilter(forward: true)
        }
    }

    private func cycleFilter(forward: Bool) {
        let all = CameraFilter.allCases
        guard let index = all.firstIndex(of: filter) else { return }
        let count = all.count
        let next = (index + (forward ? 1 : -1) + count) % count
        setFilter(all[next])
    }

    private func jumpToFilter(_ digit: Int) {
        let all = CameraFilter.allCases
        let index = min(max(digit - 1, 0), all.count - 1)
        setFilter(all[index])
    }

    private func cycleStrip() {
        let all = CameraStripMode.allCases
        guard let index = all.firstIndex(of: stripMode) else { return }
        stripMode = all[(index + 1) % all.count]
        SoundManager.shared.playPop()
    }

    private func setFilter(_ new: CameraFilter) {
        filter = new
        rainbowTimer?.invalidate()
        rainbowTimer = nil

        let ciFilter = new.makeCIFilter()
        liveCIFilter = ciFilter

        if new == .rainbow, let ciFilter {
            var angle = 0.0
            let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                angle += 0.03
                ciFilter.setValue(angle, forKey: kCIInputAngleKey)
            }
            RunLoop.main.add(timer, forMode: .common)
            rainbowTimer = timer
        }

        presentFilterPill()
    }

    private func presentFilterPill() {
        pillWorkItem?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            showFilterPill = true
        }
        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.3)) {
                showFilterPill = false
            }
        }
        pillWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }
}

/// Hosts the live `CameraPreviewView` (an `AVCaptureVideoPreviewLayer`)
/// and keeps its mirroring and filter in sync with SwiftUI state.
private struct CameraPreviewRepresentable: NSViewRepresentable {
    let session: AVCaptureSession
    var mirrored: Bool
    var filter: CIFilter?

    func makeNSView(context: Context) -> CameraPreviewView {
        CameraPreviewView(session: session)
    }

    func updateNSView(_ nsView: CameraPreviewView, context: Context) {
        nsView.setMirrored(mirrored)
        nsView.previewLayer.filters = filter.map { [$0] }
    }
}

/// A quick radial burst of stars from the center — the "you took a
/// photo!" celebration, since there is no actual photo to show.
private struct ShotBurst: View {
    @State private var expand = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.yellow)
                    .offset(
                        x: expand ? cos(Double(i) / 8 * 2 * .pi) * 130 : 0,
                        y: expand ? sin(Double(i) / 8 * 2 * .pi) * 130 : 0
                    )
                    .opacity(expand ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                expand = true
            }
        }
    }
}
