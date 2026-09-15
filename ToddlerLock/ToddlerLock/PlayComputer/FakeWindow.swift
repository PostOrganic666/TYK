import SwiftUI

// MARK: - Window manager

/// Holds the pretend windows for the Play Computer desktop.
/// The array runs back to front, so the last entry is the front window.
final class WindowManager: ObservableObject {

    struct OpenWindow: Identifiable, Equatable {
        /// The app id. One window per app keeps the desktop simple for a toddler.
        let id: String
        var frame: CGRect
        var isMinimized: Bool = false
        var isZoomed: Bool = false
        /// Frame to restore when the green button turns zoom off.
        var restoreFrame: CGRect = .zero
    }

    @Published private(set) var windows: [OpenWindow] = []

    /// Desktop size in points. The manager clamps every window to it.
    var bounds: CGSize = CGSize(width: 1280, height: 800)

    /// Height reserved at the top for the menu bar.
    let menuBarHeight: CGFloat = 28
    /// Height reserved at the bottom for the dock.
    let dockReserve: CGFloat = 96

    private var cascadeStep = 0

    // MARK: Queries

    var frontWindow: OpenWindow? {
        windows.last { !$0.isMinimized }
    }

    func isOpen(_ id: String) -> Bool {
        windows.contains { $0.id == id }
    }

    func isRunning(_ id: String) -> Bool {
        isOpen(id)
    }

    func isFront(_ id: String) -> Bool {
        frontWindow?.id == id
    }

    func index(of id: String) -> Int? {
        windows.firstIndex { $0.id == id }
    }

    // MARK: Commands

    /// Open the app, or bring it forward when it is already open.
    func open(_ app: ComputerApp) {
        if let i = index(of: app.id) {
            windows[i].isMinimized = false
            bringToFront(app.id)
            return
        }

        let size = clampSize(app.defaultSize)
        let offset = CGFloat(cascadeStep % 5) * 26
        cascadeStep += 1

        var origin = CGPoint(
            x: (bounds.width - size.width) / 2 + offset,
            y: (bounds.height - size.height) / 2 - 20 + offset
        )
        origin.y = max(origin.y, menuBarHeight + 8)

        var window = OpenWindow(id: app.id, frame: CGRect(origin: origin, size: size))
        window.restoreFrame = window.frame
        windows.append(window)
        clamp(id: app.id)
        updateFocus()
    }

    func close(_ id: String) {
        windows.removeAll { $0.id == id }
        updateFocus()
    }

    func minimize(_ id: String) {
        guard let i = index(of: id) else { return }
        windows[i].isMinimized = true
        updateFocus()
    }

    func toggleZoom(_ id: String, defaultSize: CGSize) {
        guard let i = index(of: id) else { return }
        if windows[i].isZoomed {
            let restore = windows[i].restoreFrame
            windows[i].frame = restore.isEmpty
                ? centeredFrame(for: defaultSize)
                : restore
            windows[i].isZoomed = false
        } else {
            windows[i].restoreFrame = windows[i].frame
            let inset: CGFloat = 24
            windows[i].frame = CGRect(
                x: inset,
                y: menuBarHeight + 10,
                width: bounds.width - inset * 2,
                height: bounds.height - menuBarHeight - dockReserve - 10
            )
            windows[i].isZoomed = true
        }
        bringToFront(id)
    }

    func bringToFront(_ id: String) {
        guard let i = index(of: id), i != windows.count - 1 else {
            updateFocus()
            return
        }
        let window = windows.remove(at: i)
        windows.append(window)
        updateFocus()
    }

    func move(_ id: String, to origin: CGPoint) {
        guard let i = index(of: id) else { return }
        windows[i].frame.origin = origin
        clamp(id: id)
    }

    /// Re-clamp every window after the desktop changes size.
    func layout(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        bounds = size
        for window in windows { clamp(id: window.id) }
    }

    // MARK: Helpers

    private func centeredFrame(for size: CGSize) -> CGRect {
        let clamped = clampSize(size)
        return CGRect(
            x: (bounds.width - clamped.width) / 2,
            y: (bounds.height - clamped.height) / 2 - 20,
            width: clamped.width,
            height: clamped.height
        )
    }

    private func clampSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: min(size.width, max(320, bounds.width - 48)),
            height: min(size.height, max(240, bounds.height - menuBarHeight - dockReserve - 20))
        )
    }

    /// Keep enough of the title bar on screen for a small hand to grab it.
    private func clamp(id: String) {
        guard let i = index(of: id) else { return }
        var frame = windows[i].frame
        frame.size = clampSize(frame.size)
        let edge: CGFloat = 120
        frame.origin.x = max(-frame.width + edge, min(frame.origin.x, bounds.width - edge))
        frame.origin.y = max(menuBarHeight + 4, min(frame.origin.y, bounds.height - 72))
        windows[i].frame = frame
    }

    private func updateFocus() {
        let front = frontWindow?.id
        if ComputerInput.shared.focusedAppID != front {
            ComputerInput.shared.focusedAppID = front
        }
    }
}

// MARK: - Quick Look

/// A one-page preview panel, like Quick Look on a real Mac.
struct QuickLookItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let emoji: String
    let line: String
}

/// Any pretend app can show a preview through this shared object.
final class QuickLookCenter: ObservableObject {
    static let shared = QuickLookCenter()
    @Published var item: QuickLookItem?

    private init() {}

    func show(title: String, emoji: String, line: String) {
        SoundManager.shared.playPop()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
            item = QuickLookItem(title: title, emoji: emoji, line: line)
        }
    }

    func hide() {
        withAnimation(.easeOut(duration: 0.18)) { item = nil }
    }
}

/// The floating preview panel.
struct QuickLookPanel: View {
    let item: QuickLookItem
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TrafficLight(color: .trafficRed, symbol: "xmark", active: true, action: onClose)
                Spacer()
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Color.clear.frame(width: 14, height: 14)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color(white: 0.97))

            VStack(spacing: 18) {
                Text(item.emoji)
                    .font(.system(size: 130))
                Text(item.line)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .frame(width: 420, height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 34, y: 18)
    }
}

// MARK: - Traffic lights

extension Color {
    static let trafficRed = Color(red: 1.0, green: 0.37, blue: 0.35)
    static let trafficYellow = Color(red: 1.0, green: 0.74, blue: 0.24)
    static let trafficGreen = Color(red: 0.24, green: 0.79, blue: 0.29)
}

/// One of the three round window buttons.
struct TrafficLight: View {
    let color: Color
    let symbol: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(active ? color : Color.black.opacity(0.16))
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 0.5))
                if active {
                    Image(systemName: symbol)
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundColor(.black.opacity(0.55))
                }
            }
            .contentShape(Circle().inset(by: -6))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

// MARK: - Window chrome

/// A pretend macOS window. Drag the title bar, press the three round buttons.
struct FakeWindowView: View {
    let app: ComputerApp
    let window: WindowManager.OpenWindow
    let isFront: Bool
    let onFocus: () -> Void
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onZoom: () -> Void
    let onMove: (CGPoint) -> Void

    @State private var dragOrigin: CGPoint?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Rectangle()
                .fill(Color.black.opacity(0.14))
                .frame(height: 1)
            app.make()
                .environmentObject(ComputerInput.shared)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .clipped()
        }
        .frame(width: window.frame.width, height: window.frame.height)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color.black.opacity(isFront ? 0.18 : 0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(isFront ? 0.34 : 0.18),
                radius: isFront ? 30 : 14, y: isFront ? 16 : 8)
        .scaleEffect(appeared ? 1 : 0.88)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.74)) { appeared = true }
        }
        .onPressDown(onFocus)
    }

    private var titleBar: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.98), Color(white: 0.93)],
                startPoint: .top, endPoint: .bottom
            )

            Text(app.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black.opacity(isFront ? 0.72 : 0.38))

            HStack(spacing: 8) {
                TrafficLight(color: .trafficRed, symbol: "xmark", active: isFront, action: onClose)
                TrafficLight(color: .trafficYellow, symbol: "minus", active: isFront, action: onMinimize)
                TrafficLight(color: .trafficGreen, symbol: "arrow.up.left.and.arrow.down.right", active: isFront, action: onZoom)
                Spacer()
            }
            .padding(.leading, 13)
        }
        .frame(height: 38)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    if dragOrigin == nil {
                        dragOrigin = window.frame.origin
                        onFocus()
                    }
                    guard let start = dragOrigin else { return }
                    onMove(CGPoint(x: start.x + value.translation.width,
                                   y: start.y + value.translation.height))
                }
                .onEnded { _ in dragOrigin = nil }
        )
    }
}
