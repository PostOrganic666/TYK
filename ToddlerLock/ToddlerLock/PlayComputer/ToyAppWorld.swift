import SwiftUI

// World apps ported from WorldMiniApps.swift (iOS): Weather, Clock, Maps,
// Photos. Mouse click replaces tap; keyboard adds shortcuts a finger
// never had.

// MARK: - Weather

/// Click anywhere in the sky, or press Space, to change the weather.
/// Rain, snow, and storms fall for real; the forecast is for the
/// grown-ups.
struct WeatherToyApp: View {
    private enum Kind: CaseIterable, Equatable {
        case sunny, cloudy, rainy, stormy, snowy, rainbow

        var emoji: String {
            switch self {
            case .sunny: return "☀️"
            case .cloudy: return "☁️"
            case .rainy: return "🌧️"
            case .stormy: return "⛈️"
            case .snowy: return "❄️"
            case .rainbow: return "🌈"
            }
        }

        var colors: [Color] {
            switch self {
            case .sunny: return [.cyan, .blue]
            case .cloudy: return [Color(white: 0.75), Color(white: 0.45)]
            case .rainy: return [Color(white: 0.5), Color(red: 0.2, green: 0.25, blue: 0.4)]
            case .stormy: return [Color(white: 0.3), .black]
            case .snowy: return [Color(white: 0.9), Color(red: 0.6, green: 0.7, blue: 0.85)]
            case .rainbow: return [.pink, .purple]
            }
        }

        var particle: String? {
            switch self {
            case .rainy: return "💧"
            case .stormy: return "⚡"
            case .snowy: return "❄️"
            default: return nil
            }
        }

        var temperature: String {
            switch self {
            case .sunny: return "78°"
            case .cloudy: return "64°"
            case .rainy: return "55°"
            case .stormy: return "51°"
            case .snowy: return "28°"
            case .rainbow: return "72°"
            }
        }

        var forecast: String {
            switch self {
            case .sunny: return "Tomorrow: 100% chance of crumbs."
            case .cloudy: return "Nap advisory in effect until 3 PM."
            case .rainy: return "Puddles: yes. Boots: negotiable."
            case .stormy: return "Wind from the direction of the cookie jar."
            case .snowy: return "Mittens will be lost by noon."
            case .rainbow: return "Unicorn sightings likely."
            }
        }
    }

    private struct Flake: Identifiable {
        let id = UUID()
        let x: CGFloat
        let size: CGFloat
        let duration: Double
    }

    @State private var kind: Kind = .sunny
    @State private var flakes: [Flake] = []
    @State private var spin = false
    @State private var rainTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: kind.colors, startPoint: .top, endPoint: .bottom)
                    .animation(.easeInOut(duration: 0.6), value: kind)

                if let particle = kind.particle {
                    ForEach(flakes) { flake in
                        FallingText(text: particle, x: flake.x, size: flake.size,
                                    duration: flake.duration, height: geo.size.height)
                    }
                }

                VStack(spacing: 10) {
                    MiniAppTitle(text: "Weather", subtitle: "Click the sky")
                    Spacer()
                    Text(kind.emoji)
                        .font(.system(size: 150))
                        .rotationEffect(.degrees(kind == .sunny && spin ? 360 : 0))
                        .animation(kind == .sunny ? .linear(duration: 12).repeatForever(autoreverses: false) : .default, value: spin)
                        .id(kind.emoji)
                        .transition(.scale.combined(with: .opacity))
                    Text(kind.temperature)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(kind.forecast)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Spacer()
                    Spacer().frame(height: MiniAppLayout.inset)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { next() }
            .onAppear {
                spin = true
                rainTask = Task {
                    while !Task.isCancelled {
                        if kind.particle != nil {
                            flakes.append(Flake(x: CGFloat.random(in: 10...max(20, geo.size.width - 10)),
                                                size: CGFloat.random(in: 22...44),
                                                duration: kind == .snowy ? Double.random(in: 4...7) : Double.random(in: 1.2...2.2)))
                            if flakes.count > 50 { flakes.removeFirst(flakes.count - 50) }
                        }
                        try? await Task.sleep(nanoseconds: 220_000_000)
                    }
                }
            }
            .onDisappear { rainTask?.cancel() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "weather") { press in
            if press.isSpace { next() }
        }
    }

    private func next() {
        let all = Kind.allCases
        let index = (all.firstIndex(of: kind)! + 1) % all.count
        withAnimation(.spring(duration: 0.4)) { kind = all[index] }
        flakes.removeAll()
        SoundManager.shared.playWhoosh()
        if kind == .stormy {
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                SoundManager.shared.playPop()
            }
        }
    }
}

// MARK: - Clock

/// A big clock the kid can spin by dragging the hands. Every full turn a
/// cuckoo pops out. Arrow keys nudge the minute hand and Return rings
/// the bell.
struct ClockToyApp: View {
    @State private var minuteAngle: Double = 0   // degrees, 0 = 12 o'clock
    @State private var lastDragAngle: Double?
    @State private var cuckoo = false
    @State private var ringing = false
    @State private var turns = 0

    private let hourNames = [
        "Snack o'clock", "Wiggle o'clock", "Book o'clock", "Splash o'clock",
        "Nap o'clock", "Dance o'clock", "Hug o'clock", "Blocks o'clock",
        "Bubble o'clock", "Sock o'clock", "Giggle o'clock", "Bedtime o'clock",
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 16) {
                MiniAppTitle(text: "Clock", subtitle: "Drag the hands")

                Text(hourNames[hourIndex])
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)
                    .id(hourIndex)
                    .transition(.scale)

                Spacer()

                ZStack {
                    Text(cuckoo ? "🐦" : "🏠")
                        .font(.system(size: 44))
                        .offset(y: -190)
                        .scaleEffect(cuckoo ? 1.5 : 1)

                    Circle()
                        .fill(.white)
                        .frame(width: 300, height: 300)
                        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
                    ForEach(0..<12, id: \.self) { i in
                        Text("\(i == 0 ? 12 : i)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .offset(y: -120)
                            .rotationEffect(.degrees(Double(i) * 30))
                    }
                    Capsule()
                        .fill(.black)
                        .frame(width: 12, height: 90)
                        .offset(y: -40)
                        .rotationEffect(.degrees(minuteAngle / 12))
                    Capsule()
                        .fill(.red)
                        .frame(width: 8, height: 125)
                        .offset(y: -58)
                        .rotationEffect(.degrees(minuteAngle))
                    Circle().fill(.black).frame(width: 20, height: 20)
                }
                .rotationEffect(.degrees(ringing ? 4 : 0))
                .animation(ringing ? .easeInOut(duration: 0.08).repeatCount(9, autoreverses: true) : .default, value: ringing)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            let center = CGPoint(x: 150, y: 150)
                            let angle = atan2(value.location.x - center.x, center.y - value.location.y) * 180 / .pi
                            if let last = lastDragAngle {
                                var delta = angle - last
                                if delta > 180 { delta -= 360 }
                                if delta < -180 { delta += 360 }
                                nudge(by: delta)
                            }
                            lastDragAngle = angle
                        }
                        .onEnded { _ in lastDragAngle = nil }
                )

                Spacer()

                MiniAppRoundButton(emoji: "🔔", tint: .yellow.opacity(0.7), size: 70) {
                    ring()
                }
                .padding(.bottom, MiniAppLayout.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "clock") { press in
            if press.isReturn {
                ring()
            } else if let arrow = press.arrow {
                switch arrow {
                case .up, .right: nudge(by: 6)
                case .down, .left: nudge(by: -6)
                }
            }
        }
    }

    private var hourIndex: Int {
        let hours = Int(floor(minuteAngle / 360))
        return ((hours % 12) + 12) % 12
    }

    private func nudge(by delta: Double) {
        let before = Int(floor(minuteAngle / 360))
        let previousStep = Int(minuteAngle / 30)
        minuteAngle += delta
        let after = Int(floor(minuteAngle / 360))
        if before != after { fullTurn() }
        if Int(minuteAngle / 30) != previousStep {
            SoundManager.shared.playKeypadTone(digit: Int(abs(minuteAngle / 30)) % 10)
        }
    }

    private func fullTurn() {
        turns += 1
        SoundManager.shared.playRing()
        withAnimation(.spring(duration: 0.3)) { cuckoo = true }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation { cuckoo = false }
        }
    }

    private func ring() {
        ringing = true
        Task {
            for _ in 0..<3 {
                SoundManager.shared.playRing()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            ringing = false
        }
    }
}

// MARK: - Maps

/// A cartoon town. Click anywhere and the car drives there, honking.
/// Arrow keys nudge the car too.
struct MapsToyApp: View {
    private struct Place {
        let emoji: String
        let name: String
        let note: String
        let at: CGPoint   // relative 0...1
    }

    private let places = [
        Place(emoji: "🏠", name: "Home", note: "Snacks: yes.", at: CGPoint(x: 0.2, y: 0.25)),
        Place(emoji: "🍦", name: "Ice Cream", note: "Closed. Always. Sorry.", at: CGPoint(x: 0.8, y: 0.22)),
        Place(emoji: "🏫", name: "School", note: "Nap mats inside.", at: CGPoint(x: 0.75, y: 0.5)),
        Place(emoji: "🐄", name: "Farm", note: "The cow says hi.", at: CGPoint(x: 0.22, y: 0.55)),
        Place(emoji: "🌳", name: "Park", note: "Swings: 2. Toddlers: 40.", at: CGPoint(x: 0.5, y: 0.38)),
        Place(emoji: "🏖️", name: "Beach", note: "Sand goes in everything.", at: CGPoint(x: 0.5, y: 0.7)),
        Place(emoji: "🏥", name: "Vet", note: "Deborah is not going.", at: CGPoint(x: 0.82, y: 0.78)),
        Place(emoji: "🎪", name: "Circus", note: "Same as home, more clowns.", at: CGPoint(x: 0.18, y: 0.8)),
    ]

    private let statusLines = [
        "ETA: eventually.",
        "Rerouting around a puddle…",
        "Turn left at the big dog.",
        "Traffic: one duck.",
        "You have arrived. Probably.",
    ]

    @State private var car = CGPoint(x: 0.5, y: 0.55)
    @State private var facingLeft = false
    @State private var status = "Click the map to drive"
    @State private var arrivedNote: String?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color(red: 0.55, green: 0.8, blue: 0.5)

                Canvas { context, _ in
                    var roads = Path()
                    for f in [0.25, 0.5, 0.75] {
                        roads.move(to: CGPoint(x: 0, y: size.height * f))
                        roads.addLine(to: CGPoint(x: size.width, y: size.height * f))
                        roads.move(to: CGPoint(x: size.width * f, y: 0))
                        roads.addLine(to: CGPoint(x: size.width * f, y: size.height))
                    }
                    context.stroke(roads, with: .color(Color(white: 0.35)), lineWidth: 28)
                    context.stroke(roads, with: .color(.yellow.opacity(0.8)),
                                   style: StrokeStyle(lineWidth: 3, dash: [16, 14]))
                }

                ForEach(Array(places.enumerated()), id: \.offset) { _, place in
                    Text(place.emoji)
                        .font(.system(size: 52))
                        .position(x: place.at.x * size.width, y: place.at.y * size.height)
                }

                Text("🚗")
                    .font(.system(size: 54))
                    .scaleEffect(x: facingLeft ? -1 : 1)
                    .position(x: car.x * size.width, y: car.y * size.height)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)

                if let note = arrivedNote {
                    PopBubble(text: note)
                        .position(x: size.width / 2, y: size.height * 0.16)
                        .id(note)
                }

                VStack {
                    MiniAppTitle(text: "Maps", subtitle: status)
                        .shadow(color: .black.opacity(0.4), radius: 3)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                drive(to: CGPoint(x: location.x / size.width, y: location.y / size.height))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "maps") { press in
            guard let arrow = press.arrow else { return }
            let step: CGFloat = 0.05
            var target = car
            switch arrow {
            case .up: target.y -= step
            case .down: target.y += step
            case .left: target.x -= step
            case .right: target.x += step
            }
            drive(to: target)
        }
    }

    private func drive(to target: CGPoint) {
        let clamped = CGPoint(x: min(max(target.x, 0.06), 0.94), y: min(max(target.y, 0.18), 0.82))
        facingLeft = clamped.x < car.x
        let distance = hypot(clamped.x - car.x, clamped.y - car.y)
        SoundManager.shared.playRing()
        status = statusLines.randomElement()!
        arrivedNote = nil
        withAnimation(.easeInOut(duration: 0.6 + Double(distance) * 2.2)) {
            car = clamped
        }
        Task {
            try? await Task.sleep(nanoseconds: UInt64((0.6 + Double(distance) * 2.2) * 1_000_000_000))
            if let place = places.first(where: { hypot($0.at.x - car.x, $0.at.y - car.y) < 0.1 }) {
                SoundManager.shared.playBabble()
                withAnimation { arrivedNote = "\(place.emoji) \(place.name): \(place.note)" }
            } else {
                SoundManager.shared.playPop()
            }
        }
    }
}

// MARK: - Photos

/// The family's real photos, shown only when a parent already granted
/// access. Never triggers a permission prompt. Otherwise a cheerful
/// emoji album. Display-only. Left and right arrows move between
/// full-size photos.
struct PhotosToyApp: View {
    @StateObject private var library = PhotoLibraryService()
    @State private var useLibrary = false
    @State private var fullscreenIndex: Int?

    private let album = ["🐶", "🌈", "🏖️", "🎂", "🐱", "🌻", "🚂", "🦋", "🍎", "⛄", "🎈", "🐘", "🌙", "🍕", "🐠", "🎨"]
    private let albumColors: [Color] = [.pink, .mint, .orange, .cyan, .purple, .yellow]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)

    private var libraryItems: [PhotoItem] {
        Array(library.items.filter { !$0.isVideo }.prefix(90))
    }

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 0) {
                MiniAppTitle(text: "Photos", color: .white)
                    .padding(.bottom, 10)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 4) {
                        if useLibrary {
                            ForEach(Array(libraryItems.enumerated()), id: \.offset) { index, item in
                                Button {
                                    SoundManager.shared.playPop()
                                    withAnimation(.spring(duration: 0.3)) { fullscreenIndex = index }
                                } label: {
                                    LibraryThumb(item: item, library: library)
                                }
                                .buttonStyle(SquishyButtonStyle())
                            }
                        } else {
                            ForEach(Array(album.enumerated()), id: \.offset) { i, emoji in
                                Button {
                                    SoundManager.shared.playPop()
                                    withAnimation(.spring(duration: 0.3)) { fullscreenIndex = i }
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 54))
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .background(albumColors[i % albumColors.count].opacity(0.8))
                                }
                                .buttonStyle(SquishyButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, MiniAppLayout.inset)
                }
            }

            if let index = fullscreenIndex {
                fullscreenView {
                    if useLibrary, libraryItems.indices.contains(index) {
                        FullPhotoView(item: libraryItems[index], library: library)
                    } else if !useLibrary, album.indices.contains(index) {
                        Text(album[index]).font(.system(size: 220))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard PhotoLibraryService.accessAlreadyGranted else { return }
            await library.prepare()
            useLibrary = library.state == .ready
        }
        .onAppKey(appID: "photos") { press in
            guard let arrow = press.arrow, let index = fullscreenIndex else { return }
            let count = useLibrary ? libraryItems.count : album.count
            guard count > 0 else { return }
            switch arrow {
            case .left: fullscreenIndex = (index - 1 + count) % count
            case .right: fullscreenIndex = (index + 1) % count
            default: break
            }
        }
    }

    private func fullscreenView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black
            content()
            VStack {
                Spacer()
                HStack {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { fullscreenIndex = nil }
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(.black.opacity(0.35)))
                            .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 3))
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .padding(.leading, 24)
                    .padding(.bottom, 24)
                    Spacer()
                }
            }
        }
        .transition(.opacity)
        .zIndex(2)
    }

    private struct LibraryThumb: View {
        let item: PhotoItem
        let library: PhotoLibraryService
        @State private var image: NSImage?

        var body: some View {
            ZStack {
                Color(white: 0.15)
                if let image {
                    Image(nsImage: image).resizable().scaledToFill()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .task {
                guard image == nil else { return }
                image = await library.image(for: item, targetSize: CGSize(width: 240, height: 240))
            }
        }
    }

    private struct FullPhotoView: View {
        let item: PhotoItem
        let library: PhotoLibraryService
        @State private var image: NSImage?

        var body: some View {
            ZStack {
                if let image {
                    Image(nsImage: image).resizable().scaledToFit()
                } else {
                    ProgressView().tint(.white)
                }
            }
            .task {
                image = await library.image(for: item, targetSize: CGSize(width: 1600, height: 1200))
            }
        }
    }
}
