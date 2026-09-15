import SwiftUI

// Creative apps ported from CreativeMiniApps.swift (iOS): Paint, Music,
// Stickers. Mouse drag replaces finger drag; typed keys add shortcuts a
// finger never had.

// MARK: - Paint

/// Drag to paint. Nine colors, a rainbow brush, and a trash can. Nothing
/// is saved anywhere. Any letter key cycles the color, Space toggles the
/// rainbow brush, and Delete clears the canvas.
struct PaintToyApp: View {
    private struct Stroke: Identifiable {
        let id = UUID()
        var points: [CGPoint]
        let color: Color
        let width: CGFloat
    }

    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?
    @State private var colorIndex = 0
    @State private var rainbow = false
    @State private var hue = 0.0
    @State private var brush: CGFloat = 22

    private let palette: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .brown, .black]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 0.93)

                Canvas { context, _ in
                    for stroke in strokes + (current.map { [$0] } ?? []) {
                        var path = Path()
                        if stroke.points.count == 1, let p = stroke.points.first {
                            path.addEllipse(in: CGRect(x: p.x - stroke.width / 2, y: p.y - stroke.width / 2,
                                                       width: stroke.width, height: stroke.width))
                            context.fill(path, with: .color(stroke.color))
                        } else {
                            path.addLines(stroke.points)
                            context.stroke(path, with: .color(stroke.color),
                                           style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if current == nil {
                                current = Stroke(points: [value.location], color: activeColor, width: brush)
                                SoundManager.shared.playTouchTone(normalizedX: value.location.x / max(geo.size.width, 1))
                            } else {
                                current?.points.append(value.location)
                                if rainbow, let seg = current, seg.points.count > 6 {
                                    strokes.append(seg)
                                    hue = (hue + 0.03).truncatingRemainder(dividingBy: 1)
                                    current = Stroke(points: [seg.points.last!, value.location], color: activeColor, width: brush)
                                }
                            }
                        }
                        .onEnded { _ in
                            if let stroke = current { strokes.append(stroke) }
                            current = nil
                            if strokes.count > 600 { strokes.removeFirst(strokes.count - 600) }
                        }
                )

                VStack {
                    MiniAppTitle(text: "Paint", color: .black.opacity(0.75))
                    Spacer()
                    toolbar
                        .padding(.bottom, MiniAppLayout.inset)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "paint") { press in
            if press.isSpace {
                rainbow.toggle()
                SoundManager.shared.playPop()
            } else if press.isDelete {
                withAnimation { strokes.removeAll() }
                SoundManager.shared.playWhoosh()
            } else if let c = press.characters?.first, c.isLetter {
                colorIndex = (colorIndex + 1) % palette.count
                rainbow = false
                SoundManager.shared.playPop()
            }
        }
    }

    private var activeColor: Color {
        rainbow ? Color(hue: hue, saturation: 0.95, brightness: 1) : palette[colorIndex]
    }

    private var toolbar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(Array(palette.enumerated()), id: \.offset) { index, swatch in
                    Button {
                        colorIndex = index
                        rainbow = false
                        SoundManager.shared.playPop()
                    } label: {
                        Circle()
                            .fill(swatch)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(.white, lineWidth: colorIndex == index && !rainbow ? 4 : 0))
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
            HStack(spacing: 18) {
                MiniAppRoundButton(emoji: "🌈", tint: rainbow ? .white.opacity(0.9) : .white.opacity(0.35), size: 58) {
                    rainbow.toggle()
                    SoundManager.shared.playPop()
                }
                MiniAppRoundButton(symbol: "circle.fill", tint: brush > 30 ? .black.opacity(0.6) : .black.opacity(0.3), size: 58) {
                    brush = brush > 30 ? 14 : brush + 14
                    SoundManager.shared.playPop()
                }
                MiniAppRoundButton(symbol: "trash.fill", tint: .red.opacity(0.7), size: 58) {
                    withAnimation { strokes.removeAll() }
                    SoundManager.shared.playWhoosh()
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24).fill(.black.opacity(0.08)))
        .padding(.horizontal, 16)
    }
}

// MARK: - Music

/// A rainbow piano and drum pads. Click a key, or press any letter:
/// letters A to Z map onto the eight keys in order. Number keys hit the
/// drums.
struct MusicToyApp: View {
    private let keyColors: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .indigo, .purple]
    @State private var litKey: Int?
    @State private var songTask: Task<Void, Never>?
    @State private var playingSong = false

    /// Pentatonic index steps, so anything played sounds nice.
    private let tune = [0, 2, 4, 2, 5, 4, 2, 0, 1, 4, 5, 4, 7, 5, 4, 1]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.55, green: 0.1, blue: 0.3), .black],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 14) {
                MiniAppTitle(text: "Music", subtitle: "Click the keys. Bang the drums.")

                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(keyColors[i].opacity(litKey == i ? 1.0 : 0.85))
                            .overlay(
                                Text(["🐻", "🐰", "🐸", "🐥", "🐟", "🐳", "🦄", "⭐"][i])
                                    .font(.system(size: 26))
                                    .padding(.bottom, 12),
                                alignment: .bottom
                            )
                            .scaleEffect(litKey == i ? 0.96 : 1)
                            .onPressDown { play(i) }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 14)

                HStack(spacing: 18) {
                    drum("🥁", tint: .orange) { SoundManager.shared.playPop() }
                    drum("🔔", tint: .yellow) { SoundManager.shared.playRing() }
                    drum("🎺", tint: .pink) { SoundManager.shared.playBabble() }
                    drum(playingSong ? "⏹" : "🎵", tint: .green) { toggleSong() }
                }
                .padding(.bottom, MiniAppLayout.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear { songTask?.cancel() }
        .onAppKey(appID: "music") { press in
            guard let c = press.characters?.first else { return }
            if c.isNumber, let digit = c.wholeNumberValue {
                switch digit % 3 {
                case 0: SoundManager.shared.playPop()
                case 1: SoundManager.shared.playRing()
                default: SoundManager.shared.playBabble()
                }
            } else if c.isLetter, let scalar = c.uppercased().unicodeScalars.first {
                let index = Int(scalar.value) - 65
                if index >= 0 { play(index % 8) }
            }
        }
    }

    private func drum(_ emoji: String, tint: Color, action: @escaping () -> Void) -> some View {
        Text(emoji)
            .font(.system(size: 34))
            .frame(width: 70, height: 70)
            .background(Circle().fill(tint.opacity(0.85)))
            .onPressDown(action)
    }

    private func play(_ index: Int) {
        SoundManager.shared.playKeypadTone(digit: index)
        litKey = index
        Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            if litKey == index { litKey = nil }
        }
    }

    private func toggleSong() {
        if playingSong {
            songTask?.cancel()
            playingSong = false
            return
        }
        playingSong = true
        songTask = Task {
            for note in tune {
                guard !Task.isCancelled else { break }
                play(note % 8)
                try? await Task.sleep(nanoseconds: 320_000_000)
            }
            playingSong = false
        }
    }
}

// MARK: - Stickers

/// Click anywhere to slap down a sticker. Click a sticker to make it
/// dance. Any letter key also drops a sticker at a random spot.
struct StickersToyApp: View {
    private struct Sticker: Identifiable {
        let id = UUID()
        let emoji: String
        let position: CGPoint
        let rotation: Double
        let size: CGFloat
    }

    @State private var stickers: [Sticker] = []
    @State private var dancing: UUID?
    @State private var size: CGSize = CGSize(width: 820, height: 600)

    private let set = ["⭐", "🌈", "🦄", "🐶", "🐱", "🍓", "🚗", "🌸", "🐸", "🍩", "🎈", "🦋", "🐢", "🍪", "🌙", "🐙"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.6, blue: 0.1)],
                               startPoint: .top, endPoint: .bottom)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        place(at: location)
                    }

                ForEach(stickers) { sticker in
                    Text(sticker.emoji)
                        .font(.system(size: sticker.size))
                        .rotationEffect(.degrees(sticker.rotation))
                        .scaleEffect(dancing == sticker.id ? 1.4 : 1)
                        .position(sticker.position)
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture {
                            SoundManager.shared.playPop()
                            withAnimation(.spring(duration: 0.3)) { dancing = sticker.id }
                            Task {
                                try? await Task.sleep(nanoseconds: 350_000_000)
                                withAnimation { if dancing == sticker.id { dancing = nil } }
                            }
                        }
                }

                VStack {
                    MiniAppTitle(text: "Stickers", subtitle: "Click anywhere")
                    Spacer()
                    MiniAppRoundButton(symbol: "trash.fill", tint: .red.opacity(0.7), size: 58) {
                        withAnimation { stickers.removeAll() }
                        SoundManager.shared.playWhoosh()
                    }
                    .padding(.bottom, MiniAppLayout.inset)
                }
            }
            .onAppear { size = geo.size }
            .onChange(of: geo.size) { size = $0 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "stickers") { press in
            if let c = press.characters?.first, c.isLetter {
                place(at: CGPoint(x: CGFloat.random(in: 40...max(80, size.width - 40)),
                                   y: CGFloat.random(in: 100...max(140, size.height - 40))))
            }
        }
    }

    private func place(at point: CGPoint) {
        SoundManager.shared.playTouchTone(normalizedX: point.x / max(size.width, 1))
        withAnimation(.spring(duration: 0.35)) {
            stickers.append(Sticker(
                emoji: set.randomElement()!,
                position: point,
                rotation: Double.random(in: -25...25),
                size: CGFloat.random(in: 54...84)
            ))
            if stickers.count > 60 { stickers.removeFirst() }
        }
    }
}
