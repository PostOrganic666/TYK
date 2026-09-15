import SwiftUI

/// Play Computer: a pretend Mac desktop for a toddler.
///
/// The desktop has a menu bar, a wallpaper, icons, a dock and windows. Every
/// app inside it is a toy. Nothing here reaches the network, the disk or any
/// real app.
struct DesktopView: View {
    @StateObject private var windows = WindowManager()
    @ObservedObject private var input = ComputerInput.shared
    @ObservedObject private var quickLook = QuickLookCenter.shared

    @State private var openMenu: String?
    @State private var menuAnchors: [String: CGRect] = [:]
    @State private var selectedIcon: UUID?
    @State private var floaters: [Floater] = []

    /// A big letter drifting up from the bottom of the desktop.
    private struct Floater: Identifiable {
        let id = UUID()
        let text: String
        let x: CGFloat
        let color: Color
    }

    private let letterColors: [Color] = [
        Color(red: 1.0, green: 0.42, blue: 0.42),
        Color(red: 1.0, green: 0.72, blue: 0.30),
        Color(red: 1.0, green: 0.91, blue: 0.38),
        Color(red: 0.44, green: 0.85, blue: 0.53),
        Color(red: 0.40, green: 0.74, blue: 1.0),
        Color(red: 0.72, green: 0.55, blue: 0.98),
        Color(red: 1.0, green: 0.60, blue: 0.83),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                WallpaperView()

                // Clicking empty desktop closes menus and clears the selection.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if openMenu != nil || selectedIcon != nil || quickLook.item != nil {
                            SoundManager.shared.playPop()
                        }
                        openMenu = nil
                        selectedIcon = nil
                        quickLook.hide()
                    }

                floatingLetters(in: geo.size)

                DesktopIconsView(selected: $selectedIcon, onOpen: openDesktopItem)
                    .padding(.top, 44)
                    .padding(.trailing, 22)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                windowLayer

                MenuBarView(frontAppName: frontAppName, openMenu: $openMenu)
                    .frame(maxHeight: .infinity, alignment: .top)

                menuPanel

                DockView(
                    apps: ComputerAppRegistry.dockApps,
                    runningIDs: Set(windows.windows.map { $0.id }),
                    desktopSize: geo.size,
                    onOpen: { app in
                        openMenu = nil
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            windows.open(app)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)

                if let item = quickLook.item {
                    Color.black.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { quickLook.hide() }
                    QuickLookPanel(item: item) { quickLook.hide() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                if input.drawsOwnPointer {
                    PointerArrow()
                        .fill(Color.white)
                        .overlay(PointerArrow().stroke(Color.black.opacity(0.75), lineWidth: 1))
                        .frame(width: 17, height: 27)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .offset(x: input.pointer.x, y: input.pointer.y)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: DesktopSpace.name)
            .onPreferenceChange(MenuAnchorKey.self) { menuAnchors = $0 }
            .onAppear {
                windows.layout(in: geo.size)
                #if DEBUG
                applyDebugArguments()
                #endif
            }
            .onChange(of: geo.size) { newSize in windows.layout(in: newSize) }
            .onReceive(input.keyDown) { handleKey($0) }
        }
        .background(Color.black)
        .clipped()
    }

    // MARK: - Pieces

    private var frontAppName: String {
        guard let id = windows.frontWindow?.id,
              let app = ComputerAppRegistry.app(id: id) else { return "Finder" }
        return app.name
    }

    private var windowLayer: some View {
        ForEach(windows.windows) { window in
            if !window.isMinimized, let app = ComputerAppRegistry.app(id: window.id) {
                FakeWindowView(
                    app: app,
                    window: window,
                    isFront: windows.isFront(window.id),
                    onFocus: { windows.bringToFront(window.id) },
                    onClose: {
                        SoundManager.shared.playWhoosh()
                        withAnimation(.easeOut(duration: 0.18)) { windows.close(window.id) }
                    },
                    onMinimize: {
                        SoundManager.shared.playWhoosh()
                        withAnimation(.easeIn(duration: 0.26)) { windows.minimize(window.id) }
                    },
                    onZoom: {
                        SoundManager.shared.playPop()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            windows.toggleZoom(window.id, defaultSize: app.defaultSize)
                        }
                    },
                    onMove: { windows.move(window.id, to: $0) }
                )
                .position(x: window.frame.midX, y: window.frame.midY)
                .transition(.scale(scale: 0.08, anchor: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder private var menuPanel: some View {
        if let menu = openMenu, let items = FakeMenus.items[menu] {
            let anchor = menuAnchors[menu] ?? CGRect(x: 8, y: 0, width: 40, height: 28)
            FakeMenuPanel(items: items) { item in
                pickMenuItem(menu: menu, item: item)
            }
            .offset(x: max(6, anchor.minX), y: anchor.maxY + 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .transition(.opacity)
        }
    }

    private func floatingLetters(in size: CGSize) -> some View {
        ZStack {
            ForEach(floaters) { floater in
                RisingText(text: floater.text, color: floater.color, size: 116, rise: size.height * 0.45)
                    .position(x: floater.x, y: size.height - 150)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func openDesktopItem(_ item: DesktopItem) {
        switch item.kind {
        case .folder:
            SoundManager.shared.playPop()
            if let finder = ComputerAppRegistry.app(id: "finder") {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    windows.open(finder)
                }
            }
        case .document, .picture:
            QuickLookCenter.shared.show(title: item.name, emoji: item.emoji, line: item.line)
        }
    }

    private func pickMenuItem(menu: String, item: String) {
        SoundManager.shared.playPop()
        openMenu = nil
        guard item == "About This Mac", let about = ComputerAppRegistry.app(id: "about") else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            windows.open(about)
        }
    }

    #if DEBUG
    /// Screenshot hooks. `-open-app finder` opens a window, `-open-menu File`
    /// drops a menu, `-quick-look` shows a preview panel.
    private func applyDebugArguments() {
        let arguments = ProcessInfo.processInfo.arguments

        if let index = arguments.firstIndex(of: "-open-app"), index + 1 < arguments.count {
            for id in arguments[index + 1].split(separator: ",") {
                if let app = ComputerAppRegistry.app(id: String(id)) {
                    windows.open(app)
                }
            }
        }
        if let index = arguments.firstIndex(of: "-open-menu"), index + 1 < arguments.count {
            openMenu = arguments[index + 1]
        }
        // `-type "ls|hello|"` types each part and presses Return between them.
        if let index = arguments.firstIndex(of: "-type"), index + 1 < arguments.count {
            let script = arguments[index + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                for (position, part) in script.split(separator: "|", omittingEmptySubsequences: false).enumerated() {
                    if position > 0 {
                        input.keyDown.send(KeyPress(keyCode: 36, characters: "\r"))
                    }
                    for character in part {
                        input.keyDown.send(KeyPress(keyCode: 0, characters: String(character)))
                    }
                }
            }
        }
        if arguments.contains("-quick-look"), let item = DesktopItem.all.first {
            QuickLookCenter.shared.item = QuickLookItem(
                title: item.name, emoji: item.emoji, line: item.line
            )
        }
    }
    #endif

    private func handleKey(_ key: KeyPress) {
        if key.isEscape {
            if openMenu != nil {
                SoundManager.shared.playPop()
                openMenu = nil
                return
            }
            if quickLook.item != nil {
                quickLook.hide()
                return
            }
            if let front = windows.frontWindow?.id {
                SoundManager.shared.playWhoosh()
                withAnimation(.easeOut(duration: 0.18)) { windows.close(front) }
            }
            return
        }

        // With no window in front, every key drops a big letter on the desktop.
        guard windows.frontWindow == nil else { return }
        guard let character = key.printable, character != " " else {
            if key.isSpace { SoundManager.shared.playPop() }
            return
        }

        SoundManager.shared.playKeyTone(keyCode: key.keyCode)
        let floater = Floater(
            text: String(character).uppercased(),
            x: CGFloat.random(in: 0.12...0.88) * max(windows.bounds.width, 400),
            color: letterColors.randomElement() ?? .white
        )
        floaters.append(floater)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            floaters.removeAll { $0.id == floater.id }
        }
    }
}

/// The classic pointer, drawn so the lock screen can show one without the
/// system cursor.
struct PointerArrow: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [(CGFloat, CGFloat)] = [
            (0.00, 0.00), (0.00, 0.79), (0.22, 0.60),
            (0.36, 0.96), (0.53, 0.89), (0.39, 0.55), (0.66, 0.52),
        ]
        var path = Path()
        for (index, point) in points.enumerated() {
            let location = CGPoint(x: rect.minX + point.0 * rect.width,
                                   y: rect.minY + point.1 * rect.height)
            if index == 0 { path.move(to: location) } else { path.addLine(to: location) }
        }
        path.closeSubpath()
        return path
    }
}
