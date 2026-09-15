import SwiftUI

// MARK: - Finder

/// A pretend file browser. Every file is a joke and nothing can be moved,
/// renamed or deleted.
struct FinderAppView: View {

    struct FakeFile: Identifiable {
        let id = UUID()
        let name: String
        let emoji: String
        let line: String
    }

    struct Favorite: Identifiable {
        let id = UUID()
        let name: String
        let symbol: String
        let files: [FakeFile]
    }

    static let favorites: [Favorite] = [
        Favorite(name: "Snacks", symbol: "carrot.fill", files: [
            FakeFile(name: "banana.jpg (it's a banana)", emoji: "🍌", line: "It is a banana."),
            FakeFile(name: "crumbs.zip", emoji: "🍞", line: "Compressed down to one crumb."),
            FakeFile(name: "cookie.gif", emoji: "🍪", line: "The cookie is gone. It loops."),
        ]),
        Favorite(name: "Naps", symbol: "moon.zzz.fill", files: [
            FakeFile(name: "Q3 Nap Report.numbers", emoji: "😴", line: "Conclusion: we need more naps."),
            FakeFile(name: "blanket.png", emoji: "🛏️", line: "Warm. Very warm. Too warm."),
            FakeFile(name: "sheep_count.txt", emoji: "🐑", line: "1, 2, 3, 3, 3, 3, 3…"),
        ]),
        Favorite(name: "Toys", symbol: "teddybear.fill", files: [
            FakeFile(name: "dinosaur.mov", emoji: "🦕", line: "Runtime 3 seconds. Mostly stomping."),
            FakeFile(name: "blocks.app", emoji: "🧱", line: "Tower built. Tower fell. Repeat."),
            FakeFile(name: "song.mp3", emoji: "🎵", line: "Three minutes of the same note."),
        ]),
        Favorite(name: "Very Important", symbol: "star.fill", files: [
            FakeFile(name: "final_FINAL_v2.key", emoji: "🔑", line: "Slide 1 of 1. It says The End."),
            FakeFile(name: "sock_inventory.xlsx", emoji: "🧦", line: "Socks found: 1. Socks missing: 1."),
            FakeFile(name: "my_first_novel.txt", emoji: "📖", line: "Chapter 1. The dog was good. The end."),
        ]),
    ]

    @State private var selectedFavorite = 0
    @State private var selectedFile: UUID?

    private var files: [FakeFile] { Self.favorites[selectedFavorite].files }

    private let columns = [GridItem(.adaptive(minimum: 116), spacing: 18)]

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            fileGrid
        }
        .background(Color.white)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Favorites")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 4)

            ForEach(Array(Self.favorites.enumerated()), id: \.element.id) { index, favorite in
                Button {
                    SoundManager.shared.playPop()
                    selectedFavorite = index
                    selectedFile = nil
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: favorite.symbol)
                            .font(.system(size: 13))
                            .foregroundColor(selectedFavorite == index ? .white : Color.accentColor)
                            .frame(width: 18)
                        Text(favorite.name)
                            .font(.system(size: 13))
                            .foregroundColor(selectedFavorite == index ? .white : .primary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedFavorite == index ? Color.accentColor : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 7)
            }

            Spacer()
        }
        .frame(width: 176)
        .background(Color(white: 0.96))
    }

    private var fileGrid: some View {
        VStack(spacing: 0) {
            HStack {
                Text(Self.favorites[selectedFavorite].name)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(files.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color(white: 0.98))

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(files) { file in
                        fileCell(file)
                    }
                }
                .padding(18)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    private func fileCell(_ file: FakeFile) -> some View {
        let isSelected = selectedFile == file.id
        return VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 54, height: 66)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.14), radius: 2, y: 2)
                Text(file.emoji).font(.system(size: 30))
            }
            Text(file.name)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 4).fill(isSelected ? Color.accentColor : Color.clear))
        }
        .frame(width: 112)
        .contentShape(Rectangle())
        .onDoubleClick(
            single: {
                SoundManager.shared.playPop()
                selectedFile = file.id
            },
            double: {
                selectedFile = file.id
                QuickLookCenter.shared.show(title: file.name, emoji: file.emoji, line: file.line)
            }
        )
    }
}

// MARK: - Safari

/// A pretend browser. It opens three toy pages and it never reaches the
/// network.
struct SafariAppView: View {
    private enum Page { case start, animals, colors, silly, results }

    @State private var page: Page = .start
    @State private var typed = ""
    @State private var query = ""
    @State private var resultEmoji: [String] = []
    @State private var spinning: String?

    private let animals = ["🐶", "🐱", "🐮", "🐷", "🐸", "🐵", "🦊", "🐰", "🐥", "🐟", "🐝", "🦆"]
    private let sillies = ["🤪", "🙃", "🤡", "👻", "🐙", "🍕", "🚀", "🧦", "🥑", "🦖", "🎩", "🪀"]
    private let rainbow: [(String, Color)] = [
        ("Red", Color(red: 0.95, green: 0.26, blue: 0.25)),
        ("Orange", Color(red: 0.99, green: 0.58, blue: 0.16)),
        ("Yellow", Color(red: 0.99, green: 0.83, blue: 0.20)),
        ("Green", Color(red: 0.31, green: 0.76, blue: 0.40)),
        ("Blue", Color(red: 0.20, green: 0.55, blue: 0.94)),
        ("Purple", Color(red: 0.56, green: 0.36, blue: 0.87)),
        ("Pink", Color(red: 0.96, green: 0.45, blue: 0.72)),
        ("Brown", Color(red: 0.60, green: 0.42, blue: 0.29)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
        .background(Color.white)
        .onAppKey(appID: "safari") { key in
            if key.isReturn {
                search()
            } else if key.isDelete {
                if !typed.isEmpty {
                    typed.removeLast()
                    SoundManager.shared.playPop()
                }
            } else if let character = key.printable {
                typed.append(character)
                SoundManager.shared.playKeyTone(keyCode: key.keyCode)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                toolbarChevron("chevron.left") { goBack() }
                toolbarChevron("chevron.right") { SoundManager.shared.playPop() }
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(addressText)
                    .font(.system(size: 12))
                    .foregroundColor(typed.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.93)))
            .frame(maxWidth: 420)

            Button {
                SoundManager.shared.playWhoosh()
                typed = ""
                page = .start
            } label: {
                Image(systemName: "arrow.clockwise").font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(Color(white: 0.97))
    }

    private var addressText: String {
        typed.isEmpty ? "duckling.app/kids" : typed
    }

    private func toolbarChevron(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 26, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .start:
            startPage
        case .animals:
            emojiPage(title: "Animals", items: animals) { emoji in
                SoundManager.shared.playBabble()
                wiggle(emoji)
            }
        case .colors:
            colorPage
        case .silly:
            emojiPage(title: "Silly", items: sillies) { emoji in
                SoundManager.shared.playPop()
                wiggle(emoji)
            }
        case .results:
            resultsPage
        }
    }

    private var startPage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Favorites")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)

                HStack(spacing: 22) {
                    startTile("Animals", emoji: "🐶",
                              colors: [Color(red: 0.36, green: 0.78, blue: 0.99), Color(red: 0.16, green: 0.52, blue: 0.93)]) {
                        page = .animals
                    }
                    startTile("Colors", emoji: "🌈",
                              colors: [Color(red: 0.99, green: 0.62, blue: 0.30), Color(red: 0.94, green: 0.33, blue: 0.47)]) {
                        page = .colors
                    }
                    startTile("Silly", emoji: "🤪",
                              colors: [Color(red: 0.62, green: 0.48, blue: 0.96), Color(red: 0.36, green: 0.28, blue: 0.85)]) {
                        page = .silly
                    }
                }
                .padding(.horizontal, 28)

                Text("Type some letters. Then press Return.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
        }
    }

    private func startTile(_ title: String, emoji: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playWhoosh()
            withAnimation(.easeOut(duration: 0.2)) { action() }
        } label: {
            VStack(spacing: 10) {
                Text(emoji).font(.system(size: 54))
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: colors.last?.opacity(0.35) ?? .clear, radius: 8, y: 4)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func emojiPage(title: String, items: [String], tap: @escaping (String) -> Void) -> some View {
        VStack(spacing: 0) {
            pageHeader(title)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 14)], spacing: 14) {
                    ForEach(items, id: \.self) { emoji in
                        Button {
                            tap(emoji)
                        } label: {
                            Text(emoji)
                                .font(.system(size: 52))
                                .frame(width: 104, height: 104)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(white: 0.95))
                                )
                                .rotationEffect(.degrees(spinning == emoji ? 360 : 0))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(18)
            }
        }
    }

    private var colorPage: some View {
        VStack(spacing: 0) {
            pageHeader("Colors")
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 14)], spacing: 14) {
                    ForEach(Array(rainbow.enumerated()), id: \.offset) { index, entry in
                        Button {
                            SoundManager.shared.playTouchTone(
                                normalizedX: Double(index) / Double(max(rainbow.count - 1, 1))
                            )
                        } label: {
                            Text(entry.0)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 96)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(entry.1)
                                )
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(18)
            }
        }
    }

    private var resultsPage: some View {
        VStack(spacing: 0) {
            pageHeader("Results")
            VStack(spacing: 24) {
                Text("You searched for: \(query)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .padding(.top, 26)

                HStack(spacing: 14) {
                    ForEach(Array(resultEmoji.enumerated()), id: \.offset) { _, emoji in
                        Text(emoji)
                            .font(.system(size: 48))
                            .frame(width: 84, height: 84)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.95)))
                    }
                }

                Text("8 of 8 ducks agree.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func pageHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Button {
                goBack()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left").font(.system(size: 11, weight: .bold))
                    Text("Back").font(.system(size: 13))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.accentColor)

            Spacer()
            Text(title).font(.system(size: 13, weight: .semibold))
            Spacer()
            Color.clear.frame(width: 50, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color(white: 0.98))
    }

    private func goBack() {
        SoundManager.shared.playWhoosh()
        withAnimation(.easeOut(duration: 0.2)) { page = .start }
    }

    private func wiggle(_ emoji: String) {
        withAnimation(.easeInOut(duration: 0.6)) { spinning = emoji }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            if spinning == emoji { spinning = nil }
        }
    }

    private func search() {
        SoundManager.shared.playWhoosh()
        query = typed.isEmpty ? "ducks" : typed
        resultEmoji = (0..<5).map { _ in (animals + sillies).randomElement() ?? "🦆" }
        withAnimation(.easeOut(duration: 0.2)) { page = .results }
    }
}

// MARK: - Terminal

/// A pretend shell. It runs nothing. It answers everything.
struct TerminalAppView: View {
    @State private var lines: [String] = [
        "Last login: today, on a couch",
        "",
    ]
    @State private var typed = ""

    private let prompt = "toddler@macbook-toy ~ %"

    private let fallbacks = [
        "command not found. Did you mean: snack?",
        "Compiling… done. It was a sandwich.",
        "Permission granted. Permission was always granted.",
        "Error 404: nap not found",
        "Segmentation fault (core dumped into the toy box)",
        "Process 'bedtime' has been terminated by 'one more story'",
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line.isEmpty ? " " : line)
                            .id(index)
                    }
                    HStack(spacing: 0) {
                        Text("\(prompt) \(typed)")
                        Text("▋").opacity(0.85)
                    }
                    .id("cursorLine")
                }
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(red: 0.42, green: 0.96, blue: 0.47))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .background(Color(white: 0.06))
            .onChange(of: lines.count) { _ in
                proxy.scrollTo("cursorLine", anchor: .bottom)
            }
        }
        .onAppKey(appID: "terminal") { key in
            if key.isReturn {
                run()
            } else if key.isDelete {
                if !typed.isEmpty {
                    typed.removeLast()
                    SoundManager.shared.playPop()
                }
            } else if let character = key.printable {
                typed.append(character)
                SoundManager.shared.playKeyTone(keyCode: key.keyCode)
            }
        }
    }

    private func run() {
        SoundManager.shared.playPop()
        let command = typed
        lines.append("\(prompt) \(command)")
        lines.append(response(for: command))
        lines.append("")
        typed = ""
        if lines.count > 30 {
            lines.removeFirst(lines.count - 30)
        }
    }

    private func response(for command: String) -> String {
        let lower = command.lowercased()
        if lower.contains("ls") { return "naps/   snacks/   toys/   VERY_IMPORTANT.txt" }
        if lower.contains("sudo") { return "Okay. But only because you asked nicely." }
        if lower.contains("rm") { return "Nothing was deleted. Nothing is ever deleted here." }
        if lower.contains("cd") { return "You are already home." }
        if lower.contains("hello") { return "hi" }
        return fallbacks.randomElement() ?? fallbacks[0]
    }
}

// MARK: - Notes

/// A yellow pad. Typed letters land big and colorful.
struct NotesAppView: View {
    @State private var lines: [String] = [""]

    private let palette: [Color] = [
        Color(red: 0.90, green: 0.29, blue: 0.31),
        Color(red: 0.95, green: 0.55, blue: 0.16),
        Color(red: 0.32, green: 0.68, blue: 0.35),
        Color(red: 0.20, green: 0.52, blue: 0.90),
        Color(red: 0.56, green: 0.36, blue: 0.85),
        Color(red: 0.92, green: 0.36, blue: 0.62),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    SoundManager.shared.playWhoosh()
                    withAnimation(.easeOut(duration: 0.2)) { lines = [""] }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.pencil").font(.system(size: 12))
                        Text("New Note").font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.85)))
                    .contentShape(Rectangle())
                }
                .buttonStyle(SquishyButtonStyle())
                .foregroundColor(Color(red: 0.55, green: 0.40, blue: 0.05))

                Spacer()
                Text("Type anything. It is your note.")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.55, green: 0.44, blue: 0.14))
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(Color(red: 1.0, green: 0.90, blue: 0.55))

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        HStack(spacing: 3) {
                            ForEach(Array(line.enumerated()), id: \.offset) { position, character in
                                Text(String(character))
                                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                                    .foregroundColor(color(for: position, character: character))
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 52, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .background(paper)
        }
        .onAppKey(appID: "notes") { key in
            if key.isReturn {
                SoundManager.shared.playPop()
                lines.append("")
                if lines.count > 40 { lines.removeFirst() }
            } else if key.isDelete {
                SoundManager.shared.playPop()
                if var last = lines.last, !last.isEmpty {
                    last.removeLast()
                    lines[lines.count - 1] = last
                } else if lines.count > 1 {
                    lines.removeLast()
                }
            } else if let character = key.printable {
                SoundManager.shared.playKeyTone(keyCode: key.keyCode)
                lines[lines.count - 1].append(character)
            }
        }
    }

    /// Lined note paper, sized to the space it is given.
    private var paper: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color(red: 1.0, green: 0.97, blue: 0.80)
                VStack(spacing: 57) {
                    ForEach(0..<max(Int(geo.size.height / 58) + 1, 1), id: \.self) { _ in
                        Rectangle()
                            .fill(Color(red: 0.90, green: 0.84, blue: 0.60))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 72)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
    }

    private func color(for position: Int, character: Character) -> Color {
        let seed = Int(character.unicodeScalars.first?.value ?? 65) + position
        return palette[seed % palette.count]
    }
}

// MARK: - Trash

/// The trash always holds the same three pieces of broccoli.
struct TrashAppView: View {
    @State private var isEmpty = false
    @State private var status = "The trash contains: broccoli (3)"
    @State private var working = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Text("🥦")
                        .font(.system(size: 54))
                        .scaleEffect(isEmpty ? 0.1 : 1)
                        .opacity(isEmpty ? 0 : 1)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.06),
                            value: isEmpty
                        )
                }
            }
            .frame(height: 70)

            Text(status)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                emptyTrash()
            } label: {
                Text("Empty Trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(red: 0.36, green: 0.40, blue: 0.46)))
                    .contentShape(Capsule())
            }
            .buttonStyle(SquishyButtonStyle())
            .disabled(working)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.97))
    }

    private func emptyTrash() {
        guard !working else { return }
        working = true
        SoundManager.shared.playWhoosh()
        isEmpty = true
        status = "Emptying…"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            SoundManager.shared.playPop()
            isEmpty = false
            status = "The broccoli is back. It always comes back."
            working = false
        }
    }
}

// MARK: - About This Mac

/// The pretend spec sheet.
struct AboutMacView: View {
    private let rows: [(String, String)] = [
        ("Chip", "Cheddar M1"),
        ("Memory", "Short"),
        ("Storage", "Full of crackers"),
        ("Serial", "NOPE"),
    ]

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "laptopcomputer")
                .font(.system(size: 66, weight: .thin))
                .foregroundColor(.secondary)
                .padding(.top, 26)

            Text("MacBook Toy")
                .font(.system(size: 20, weight: .semibold))
            Text("(Late Bedtime, 2026)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            VStack(spacing: 7) {
                ForEach(rows, id: \.0) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.0)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 74, alignment: .trailing)
                        Text(row.1)
                            .font(.system(size: 12))
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 40)

            Spacer()

            Text("🦆")
                .font(.system(size: 26))
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98))
    }
}
