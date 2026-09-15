import SwiftUI

/// The apps that come with the pretend Mac.
enum SystemApps {
    static let all: [ComputerApp] = [finder, safari, terminal, notes, trash, about]

    static let finder = ComputerApp(
        id: "finder",
        name: "Finder",
        symbol: "face.smiling",
        colors: [Color(red: 0.44, green: 0.74, blue: 1.0), Color(red: 0.15, green: 0.45, blue: 0.92)],
        defaultSize: CGSize(width: 760, height: 470),
        make: { AnyView(FinderAppView()) }
    )

    static let safari = ComputerApp(
        id: "safari",
        name: "Safari",
        symbol: "safari",
        colors: [Color(red: 0.65, green: 0.88, blue: 1.0), Color(red: 0.16, green: 0.55, blue: 0.95)],
        defaultSize: CGSize(width: 860, height: 560),
        make: { AnyView(SafariAppView()) }
    )

    static let terminal = ComputerApp(
        id: "terminal",
        name: "Terminal",
        symbol: "terminal.fill",
        colors: [Color(white: 0.34), Color(white: 0.13)],
        defaultSize: CGSize(width: 700, height: 420),
        make: { AnyView(TerminalAppView()) }
    )

    static let notes = ComputerApp(
        id: "notes",
        name: "Notes",
        symbol: "note.text",
        colors: [Color(red: 1.0, green: 0.90, blue: 0.45), Color(red: 1.0, green: 0.74, blue: 0.20)],
        defaultSize: CGSize(width: 600, height: 440),
        make: { AnyView(NotesAppView()) }
    )

    static let trash = ComputerApp(
        id: "trash",
        name: "Trash",
        symbol: "trash.fill",
        colors: [Color(white: 0.74), Color(white: 0.48)],
        defaultSize: CGSize(width: 480, height: 360),
        badge: "3",
        make: { AnyView(TrashAppView()) }
    )

    /// Opened from the duck menu, so it keeps out of the dock.
    static let about = ComputerApp(
        id: "about",
        name: "About This Mac",
        symbol: "desktopcomputer",
        colors: [Color(white: 0.8), Color(white: 0.55)],
        defaultSize: CGSize(width: 400, height: 430),
        inDock: false,
        make: { AnyView(AboutMacView()) }
    )
}
