import SwiftUI

// MARK: - Wallpaper

/// A painted landscape, drawn with shapes so the app carries no image files.
struct WallpaperView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.13, blue: 0.40),
                        Color(red: 0.19, green: 0.32, blue: 0.68),
                        Color(red: 0.40, green: 0.62, blue: 0.86),
                        Color(red: 0.86, green: 0.71, blue: 0.68),
                        Color(red: 0.99, green: 0.83, blue: 0.62),
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // Soft glow around the sun, drawn as a fading gradient.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.86, blue: 0.64).opacity(0.42),
                                Color(red: 1.0, green: 0.80, blue: 0.60).opacity(0.14),
                                Color(red: 1.0, green: 0.80, blue: 0.60).opacity(0.0),
                            ],
                            center: .center, startRadius: 0, endRadius: geo.size.height * 0.30
                        )
                    )
                    .frame(width: geo.size.height * 0.62, height: geo.size.height * 0.62)
                    .position(x: geo.size.width * 0.70, y: geo.size.height * 0.40)

                // Sun
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color(red: 1.0, green: 0.91, blue: 0.72),
                                Color(red: 1.0, green: 0.86, blue: 0.64).opacity(0.0),
                            ],
                            center: .center, startRadius: 1, endRadius: geo.size.height * 0.085
                        )
                    )
                    .frame(width: geo.size.height * 0.18, height: geo.size.height * 0.18)
                    .position(x: geo.size.width * 0.70, y: geo.size.height * 0.40)

                cloud(width: geo.size.width * 0.24)
                    .position(x: geo.size.width * 0.22, y: geo.size.height * 0.22)
                    .opacity(0.34)
                cloud(width: geo.size.width * 0.16)
                    .position(x: geo.size.width * 0.52, y: geo.size.height * 0.15)
                    .opacity(0.24)

                // Layered hills, far to near
                HillShape(peak: 0.52, dip: 0.16, lift: 0.10)
                    .fill(Color(red: 0.32, green: 0.36, blue: 0.62).opacity(0.75))
                HillShape(peak: 0.64, dip: 0.10, lift: 0.20)
                    .fill(Color(red: 0.24, green: 0.30, blue: 0.56))
                HillShape(peak: 0.76, dip: 0.20, lift: 0.06)
                    .fill(Color(red: 0.16, green: 0.22, blue: 0.44))
                HillShape(peak: 0.88, dip: 0.08, lift: 0.14)
                    .fill(Color(red: 0.09, green: 0.13, blue: 0.30))
            }
            .ignoresSafeArea()
        }
    }

    /// A soft cloud, built from fading circles so it needs no blur filter.
    private func cloud(width: CGFloat) -> some View {
        let puff = RadialGradient(
            colors: [Color.white, Color.white.opacity(0.55), Color.white.opacity(0.0)],
            center: .center, startRadius: 0, endRadius: width * 0.22
        )
        return ZStack {
            Circle().fill(puff).frame(width: width * 0.44, height: width * 0.44)
                .offset(x: -width * 0.20, y: width * 0.03)
            Circle().fill(puff).frame(width: width * 0.60, height: width * 0.60)
                .offset(x: -width * 0.02, y: -width * 0.05)
            Circle().fill(puff).frame(width: width * 0.40, height: width * 0.40)
                .offset(x: width * 0.22, y: width * 0.02)
            Circle().fill(puff).frame(width: width * 0.30, height: width * 0.30)
                .offset(x: width * 0.38, y: width * 0.05)
        }
        .frame(width: width, height: width * 0.4)
        .scaleEffect(x: 1.25, y: 0.62)
    }
}

/// One rolling hill.
struct HillShape: Shape {
    /// Where the left edge of the hill starts, as a fraction of the height.
    let peak: CGFloat
    /// How much the middle rises above the edges.
    let dip: CGFloat
    /// How much lower the right edge sits.
    let lift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startY = rect.height * peak
        let endY = rect.height * min(peak + lift, 1.0)
        path.move(to: CGPoint(x: 0, y: startY))
        path.addCurve(
            to: CGPoint(x: rect.width, y: endY),
            control1: CGPoint(x: rect.width * 0.32, y: rect.height * (peak - dip)),
            control2: CGPoint(x: rect.width * 0.68, y: rect.height * (peak + dip * 0.4))
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Menu bar

/// The titles and items of the pretend menus.
enum FakeMenus {
    static let duck = "\u{1F986}"

    static let order = ["File", "Edit", "View", "Go", "Window", "Help"]

    static let items: [String: [String]] = [
        duck: ["About This Mac", "Sleep (no)", "Nap Mode…", "Log Out Toddler…"],
        "File": ["New Snack", "New Nap", "Open the Fridge", "Save Crackers", "Print a Duck"],
        "Edit": ["Undo the Spill", "Redo the Spill", "Cut a Banana", "Copy the Dog", "Paste the Dog", "Select All Toys"],
        "View": ["Bigger", "Even Bigger", "Upside Down", "Hide the Floor", "Show All Ducks"],
        "Go": ["Go to the Park", "Go Bananas", "Back to the Sofa", "Recent Crumbs"],
        "Window": ["Wiggle", "Stack the Blocks", "Send to the Moon", "Bring All Ducks Forward"],
        "Help": ["Ask a Grown-Up", "Ask the Duck", "What Is a Computer?", "Where Do Socks Go?"],
    ]
}

/// Reports where each menu title sits, so the dropdown lands under it.
struct MenuAnchorKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// The bar across the top of the pretend desktop.
struct MenuBarView: View {
    let frontAppName: String
    @Binding var openMenu: String?

    @State private var now = Date()
    private let tick = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            menuTitle(FakeMenus.duck, isDuck: true)
            menuTitle(frontAppName, isAppName: true)
            ForEach(FakeMenus.order, id: \.self) { title in
                menuTitle(title)
            }

            Spacer(minLength: 12)

            Image(systemName: "wifi")
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 7)
            Image(systemName: "battery.75")
                .font(.system(size: 15, weight: .regular))
                .padding(.horizontal, 7)
            Text(clockText)
                .font(.system(size: 13, weight: .regular))
                .padding(.trailing, 12)
        }
        .foregroundColor(.black.opacity(0.82))
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color.white.opacity(0.30))
            }
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 0.5)
        }
        .onReceive(tick) { now = $0 }
    }

    private var clockText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM  h:mm a"
        return formatter.string(from: now)
    }

    private func menuTitle(_ title: String, isDuck: Bool = false, isAppName: Bool = false) -> some View {
        let isOpen = openMenu == title
        return Button {
            SoundManager.shared.playPop()
            openMenu = isOpen ? nil : title
        } label: {
            Group {
                if isDuck {
                    Text(title).font(.system(size: 15))
                } else {
                    Text(title)
                        .font(.system(size: 13, weight: isAppName ? .bold : .regular))
                }
            }
            .foregroundColor(isOpen ? .white : .black.opacity(0.82))
            .padding(.horizontal, isDuck ? 11 : 9)
            .frame(height: 28)
            .background(isOpen ? Color.accentColor : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: MenuAnchorKey.self,
                    value: [title: geo.frame(in: .named(DesktopSpace.name))]
                )
            }
        )
    }
}

/// The dropdown under a menu title.
struct FakeMenuPanel: View {
    let items: [String]
    let onPick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button {
                    onPick(item)
                } label: {
                    Text(item)
                        .font(.system(size: 13))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(MenuItemStyle())
            }
        }
        .padding(.vertical, 5)
        .frame(width: 210)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous).fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.white.opacity(0.45))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
    }
}

private struct MenuItemStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : .black.opacity(0.85))
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? Color.accentColor : Color.clear)
                    .padding(.horizontal, 5)
            )
    }
}

// MARK: - Desktop icons

/// One thing sitting on the pretend desktop.
struct DesktopItem: Identifiable {
    enum Kind { case folder, document, picture }

    let id = UUID()
    let name: String
    let kind: Kind
    let emoji: String
    let line: String

    static let all: [DesktopItem] = [
        DesktopItem(name: "Very Important Taxes.pdf", kind: .document, emoji: "🦕",
                    line: "Page 1 of 1. It is a drawing of a dinosaur."),
        DesktopItem(name: "DO NOT DELETE", kind: .folder, emoji: "📂",
                    line: "The folder is empty. It has always been empty."),
        DesktopItem(name: "untitled folder 47", kind: .folder, emoji: "📁",
                    line: "Inside: untitled folder 48."),
        DesktopItem(name: "Grandma's cookie recipe", kind: .document, emoji: "🍪",
                    line: "Step 1. Ask Grandma. Step 2. Eat."),
        DesktopItem(name: "IMG_0001 (thumb).HEIC", kind: .picture, emoji: "👍",
                    line: "Preview not available. The thumb is fine."),
        DesktopItem(name: "Screenshot of a screenshot", kind: .picture, emoji: "🖼️",
                    line: "A picture of a picture of a picture."),
    ]
}

/// The column of icons down the right side.
struct DesktopIconsView: View {
    @Binding var selected: UUID?
    let onOpen: (DesktopItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(DesktopItem.all) { item in
                DesktopIconView(item: item, isSelected: selected == item.id)
                    .onDoubleClick(
                        single: {
                            SoundManager.shared.playPop()
                            selected = item.id
                        },
                        double: {
                            selected = item.id
                            onOpen(item)
                        }
                    )
            }
        }
    }
}

/// A single desktop icon with its label.
struct DesktopIconView: View {
    let item: DesktopItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            artwork
                .frame(width: 58, height: 52)
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white.opacity(0.22) : Color.clear)
                )

            Text(item.name)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 96)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor : Color.black.opacity(0.18))
                )
                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
        }
        .frame(width: 104)
        .contentShape(Rectangle())
    }

    @ViewBuilder private var artwork: some View {
        switch item.kind {
        case .folder:
            Image(systemName: "folder.fill")
                .font(.system(size: 42))
                .foregroundStyle(
                    LinearGradient(colors: [Color(red: 0.49, green: 0.76, blue: 0.96),
                                            Color(red: 0.24, green: 0.56, blue: 0.87)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
        case .document, .picture:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 38, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 2, y: 2)
                Text(item.emoji)
                    .font(.system(size: 21))
                    .offset(y: 2)
                Image(systemName: "arrow.turn.left.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.black.opacity(0.15))
                    .offset(x: 12, y: -18)
            }
        }
    }
}

// MARK: - Dock

/// The bar of app tiles across the bottom.
struct DockView: View {
    let apps: [ComputerApp]
    let runningIDs: Set<String>
    let desktopSize: CGSize
    let onOpen: (ComputerApp) -> Void

    @ObservedObject private var input = ComputerInput.shared
    @State private var bounceID: String?
    @State private var bounceUp = false

    private let spacing: CGFloat = 7
    private let hPad: CGFloat = 11
    private let maxScale: CGFloat = 1.42

    /// Tile size: 58 pt, shrinking like macOS when the dock would not fit.
    private var base: CGFloat {
        let count = CGFloat(max(apps.count, 1))
        let available = desktopSize.width - 48 - hPad * 2 - spacing * (count - 1) - dividerWidth
        return min(58, max(30, available / count))
    }

    /// Extra width taken by the divider that sits in front of Trash.
    private var dividerWidth: CGFloat {
        let index = apps.firstIndex { $0.id == "trash" } ?? 0
        return index > 0 ? spacing + 1 : 0
    }

    private var barWidth: CGFloat {
        guard !apps.isEmpty else { return 120 }
        return hPad * 2 + CGFloat(apps.count) * base
            + CGFloat(apps.count - 1) * spacing + dividerWidth
    }

    private var barHeight: CGFloat { base + 16 }

    /// Bottom edge of the dock inside the desktop.
    private var barBottom: CGFloat { desktopSize.height - 8 }

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
            )
            .frame(width: barWidth, height: barHeight)
            .shadow(color: .black.opacity(0.28), radius: 16, y: 6)
            .overlay(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                        if app.id == "trash", index > 0 {
                            Rectangle()
                                .fill(Color.black.opacity(0.18))
                                .frame(width: 1, height: base * 0.82)
                                .padding(.bottom, base * 0.06)
                        }
                        tile(app, index: index)
                    }
                }
                .padding(.bottom, 8)
            }
    }

    private func tile(_ app: ComputerApp, index: Int) -> some View {
        let scale = magnification(for: index)
        let size = base * scale
        let isRunning = runningIDs.contains(app.id)
        let bounce: CGFloat = (bounceID == app.id && bounceUp) ? -22 : 0

        return VStack(spacing: 3) {
            Button {
                open(app)
            } label: {
                RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                    .fill(
                        LinearGradient(colors: app.colors, startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                    )
                    .overlay(
                        Image(systemName: app.symbol)
                            .font(.system(size: size * 0.46, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    )
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                    .overlay(alignment: .topTrailing) {
                        if let badge = app.badge {
                            Text("\(badge)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.red))
                                .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                                .offset(x: 5, y: -4)
                        }
                    }
                    .offset(y: bounce)
            }
            .buttonStyle(SquishyButtonStyle())

            Circle()
                .fill(Color.black.opacity(isRunning ? 0.55 : 0))
                .frame(width: 4, height: 4)
        }
        .frame(width: size)
    }

    /// macOS-style magnification, driven by the virtual pointer.
    private func magnification(for index: Int) -> CGFloat {
        guard desktopSize.width > 0 else { return 1 }
        let barLeft = (desktopSize.width - barWidth) / 2
        let trashIndex = apps.firstIndex { $0.id == "trash" } ?? apps.count
        let shift: CGFloat = (index >= trashIndex && trashIndex > 0) ? dividerWidth : 0
        let center = barLeft + hPad + CGFloat(index) * (base + spacing) + base / 2 + shift
        let pointer = input.pointer

        // Only magnify while the pointer is near the dock.
        let top = barBottom - barHeight - 30
        guard pointer.y > top else { return 1 }

        let distance = abs(pointer.x - center)
        let reach: CGFloat = 105
        guard distance < reach else { return 1 }
        let falloff = cos((distance / reach) * (.pi / 2))
        return 1 + (maxScale - 1) * falloff * falloff
    }

    private func open(_ app: ComputerApp) {
        SoundManager.shared.playPop()
        bounceID = app.id
        withAnimation(.easeOut(duration: 0.16)) { bounceUp = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.45)) { bounceUp = false }
        }
        onOpen(app)
    }
}

/// Name of the coordinate space the desktop shares with its parts.
enum DesktopSpace {
    static let name = "playComputerDesktop"
}
