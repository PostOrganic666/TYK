import SwiftUI

/// One app on the pretend Mac. The desktop shell puts it in the dock and
/// opens `make()` inside a fake macOS window.
struct ComputerApp: Identifiable {
    let id: String
    let name: String
    /// Dock tile: an SF Symbol on a gradient, like real macOS app icons.
    let symbol: String
    let colors: [Color]
    /// Preferred window size. The shell clamps it to the screen.
    var defaultSize = CGSize(width: 760, height: 540)
    /// Red badge on the dock tile, for the grown-ups.
    var badge: String? = nil
    /// Keep in the dock (true) or only on the desktop/Launchpad (false).
    var inDock = true
    let make: () -> AnyView

    init(id: String, name: String, symbol: String, colors: [Color],
         defaultSize: CGSize = CGSize(width: 760, height: 540),
         badge: String? = nil, inDock: Bool = true,
         @ViewBuilder make: @escaping () -> some View) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colors = colors
        self.defaultSize = defaultSize
        self.badge = badge
        self.inDock = inDock
        let builder = make
        self.make = { AnyView(builder()) }
    }
}

/// Every app on the pretend Mac, in dock order. Each list lives in its
/// own file so several people can add apps at once.
enum ComputerAppRegistry {
    static var all: [ComputerApp] {
        SystemApps.all + ToyApps.all + MoreToyApps.all
    }

    static func app(id: String) -> ComputerApp? {
        all.first { $0.id == id }
    }

    /// Dock order: Finder first, then everything in the dock, then Trash.
    static var dockApps: [ComputerApp] {
        let every = all
        var tiles: [ComputerApp] = []
        if let finder = every.first(where: { $0.id == "finder" }) { tiles.append(finder) }
        tiles += every.filter { $0.inDock && $0.id != "finder" && $0.id != "trash" }
        if let trash = every.first(where: { $0.id == "trash" }) { tiles.append(trash) }
        return tiles
    }
}
