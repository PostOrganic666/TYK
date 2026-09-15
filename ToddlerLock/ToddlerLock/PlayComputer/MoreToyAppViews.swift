import SwiftUI

// MARK: - Games (whack-a-mole)

/// Bonk the critters when they pop out of their holes.
struct GamesMiniApp: View {
    @State private var visible: [Int: String] = [:]
    @State private var bonked: Set<Int> = []
    @State private var score = 0
    @State private var popTask: Task<Void, Never>?

    private let critters = ["🐹", "🐭", "🐰", "🐸", "🦔"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.35, green: 0.78, blue: 0.4), Color(red: 0.15, green: 0.5, blue: 0.22)],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 18) {
                MiniAppTitle(text: "Bonk!", subtitle: "Click the critters. Keys 1 to 9 work too.")
                Text("\(score)")
                    .font(.system(size: 54, weight: .heavy, design: .rounded))
                    .foregroundStyle(.yellow)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.25), value: score)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<9, id: \.self) { i in
                        hole(i)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { start() }
        .onDisappear { popTask?.cancel() }
        .onAppKey(appID: "games") { press in
            if let letter = press.letter, let n = Int(letter), (1...9).contains(n) {
                bonk(n - 1)
            }
        }
    }

    private func hole(_ i: Int) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.3, green: 0.2, blue: 0.1))
                .frame(width: 94, height: 44)
                .offset(y: 32)
            if let critter = visible[i] {
                Text(bonked.contains(i) ? "😵" : critter)
                    .font(.system(size: 56))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(height: 104)
        .contentShape(Rectangle())
        .onPressDown { bonk(i) }
        .clipped()
    }

    private func start() {
        popTask = Task {
            while !Task.isCancelled {
                let i = Int.random(in: 0..<9)
                if visible[i] == nil {
                    withAnimation(.spring(duration: 0.25)) { visible[i] = critters.randomElement() }
                    SoundManager.shared.playWhoosh()
                    Task {
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        if !bonked.contains(i) {
                            withAnimation { visible[i] = nil }
                        }
                    }
                }
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
        }
    }

    private func bonk(_ i: Int) {
        guard visible[i] != nil, !bonked.contains(i) else { return }
        bonked.insert(i)
        score += 1
        SoundManager.shared.playPop()
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation {
                visible[i] = nil
                bonked.remove(i)
            }
        }
    }
}

// MARK: - Pets

/// A pet to feed, play with, and put to sleep. It has opinions.
struct PetsMiniApp: View {
    private struct Pet {
        let face: String
        let name: String
        let sleepy: String
    }

    private let pets = [
        Pet(face: "🐶", name: "Deputy Waffles", sleepy: "😴"),
        Pet(face: "🐱", name: "Sir Fluffington", sleepy: "😴"),
        Pet(face: "🐰", name: "Nugget", sleepy: "😴"),
        Pet(face: "🐹", name: "Tiny Kevin", sleepy: "😴"),
        Pet(face: "🐢", name: "Speedy Jr.", sleepy: "😴"),
        Pet(face: "🐷", name: "Professor Snout", sleepy: "😴"),
    ]

    @State private var pet: Pet
    @State private var hearts = 2
    @State private var bounce = false
    @State private var sleeping = false
    @State private var flying: (emoji: String, id: Int)?
    @State private var bubble: String?
    @State private var flyID = 0

    private let foods = ["🍎", "🥕", "🍪", "🍌", "🧀", "🍓"]
    private let happyLines = ["Yum!", "More!", "Best day ever", "Again!", "I love you", "Tummy full"]

    init() {
        _pet = State(initialValue: [
            Pet(face: "🐶", name: "Deputy Waffles", sleepy: "😴"),
            Pet(face: "🐱", name: "Sir Fluffington", sleepy: "😴"),
            Pet(face: "🐰", name: "Nugget", sleepy: "😴"),
        ].randomElement()!)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: sleeping ? [Color(red: 0.1, green: 0.1, blue: 0.25), .black] : [Color(red: 0.95, green: 0.65, blue: 0.25), Color(red: 0.5, green: 0.32, blue: 0.15)],
                           startPoint: .top, endPoint: .bottom)
                .animation(.easeInOut(duration: 0.8), value: sleeping)

            VStack(spacing: 12) {
                MiniAppTitle(text: pet.name, subtitle: "Click the pet. Keys F, P, S, N work too.")

                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Text(i < hearts ? "❤️" : "🤍").font(.system(size: 24))
                    }
                }

                Spacer()

                ZStack {
                    Text(sleeping ? pet.sleepy : pet.face)
                        .font(.system(size: 150))
                        .scaleEffect(bounce ? 1.15 : 1)
                        .rotationEffect(.degrees(bounce ? 6 : 0))
                        .onTapGesture { poke() }
                    if sleeping {
                        Text("💤")
                            .font(.system(size: 44))
                            .offset(x: 78, y: -78)
                            .opacity(bounce ? 0.3 : 1)
                    }
                    if let flying {
                        Text(flying.emoji)
                            .font(.system(size: 54))
                            .modifier(FlyIn(id: flying.id))
                    }
                    if let bubble {
                        PopBubble(text: bubble)
                            .offset(y: -120)
                            .id(bubble)
                    }
                }

                Spacer()

                HStack(spacing: 20) {
                    MiniAppRoundButton(emoji: foods.randomElement()!, tint: .green.opacity(0.7), size: 64) { feed() }
                    MiniAppRoundButton(emoji: "🎾", tint: .yellow.opacity(0.7), size: 64) { play() }
                    MiniAppRoundButton(emoji: sleeping ? "☀️" : "🌙", tint: .indigo.opacity(0.7), size: 64) { toggleSleep() }
                    MiniAppRoundButton(symbol: "arrow.triangle.2.circlepath", tint: .white.opacity(0.2), size: 64) { newPet() }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "pets") { press in
            switch press.letter {
            case "F": feed()
            case "P": play()
            case "S": toggleSleep()
            case "N": newPet()
            default: break
            }
        }
    }

    private func wiggle() {
        withAnimation(.spring(duration: 0.25)) { bounce = true }
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(duration: 0.25)) { bounce = false }
        }
    }

    private func say(_ text: String) {
        withAnimation { bubble = text }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation { if bubble == text { bubble = nil } }
        }
    }

    private func poke() {
        if sleeping { toggleSleep(); return }
        SoundManager.shared.playBabble()
        wiggle()
    }

    private func feed() {
        if sleeping { toggleSleep() }
        flyID += 1
        flying = (foods.randomElement()!, flyID)
        SoundManager.shared.playWhoosh()
        Task {
            try? await Task.sleep(nanoseconds: 550_000_000)
            flying = nil
            SoundManager.shared.playPop()
            hearts = min(5, hearts + 1)
            wiggle()
            say(happyLines.randomElement()!)
        }
    }

    private func play() {
        if sleeping { toggleSleep() }
        SoundManager.shared.playBabble()
        wiggle()
        say(["Wheee!", "Throw it again", "Got it!", "Zoomies!"].randomElement()!)
        hearts = min(5, hearts + 1)
    }

    private func toggleSleep() {
        sleeping.toggle()
        SoundManager.shared.playWhoosh()
        if sleeping {
            say("Zzz…")
        } else {
            say("Good morning!")
            wiggle()
        }
    }

    private func newPet() {
        pet = pets.filter { $0.name != pet.name }.randomElement()!
        sleeping = false
        hearts = 2
        SoundManager.shared.playPop()
        wiggle()
        say("Hi! I'm \(pet.name)")
    }

    private struct FlyIn: ViewModifier {
        let id: Int
        @State private var progress: CGFloat = 0

        func body(content: Content) -> some View {
            content
                .offset(y: 230 - 230 * progress)
                .scaleEffect(1.2 - 0.6 * progress)
                .opacity(progress > 0.9 ? 0 : 1)
                .onAppear { withAnimation(.easeIn(duration: 0.5)) { progress = 1 } }
                .id(id)
        }
    }
}

// MARK: - Space

/// Countdown, launch, fly through the stars, land on the Moon.
struct SpaceMiniApp: View {
    private enum Phase { case ready, counting, flying, landed }

    @State private var phase: Phase = .ready
    @State private var count = 3
    @State private var rocketY: CGFloat = 0     // 0 = pad, 1 = top
    @State private var stars: [Star] = []
    @State private var starTask: Task<Void, Never>?
    @State private var spinningPlanet: Int?
    @State private var contentSize: CGSize = .zero

    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let size: CGFloat
        let duration: Double
    }

    private let planets = ["🪐", "🌍", "🌕", "☄️"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [.black, Color(red: 0.1, green: 0.05, blue: 0.3)],
                               startPoint: .top, endPoint: .bottom)

                ForEach(stars) { star in
                    FallingText(text: "✨", x: star.x, size: star.size, duration: star.duration, height: geo.size.height)
                }

                ForEach(Array(planets.enumerated()), id: \.offset) { i, planet in
                    Text(planet)
                        .font(.system(size: 50))
                        .rotationEffect(.degrees(spinningPlanet == i ? 360 : 0))
                        .position(x: geo.size.width * [0.2, 0.8, 0.5, 0.75][i],
                                  y: geo.size.height * [0.22, 0.3, 0.14, 0.55][i])
                        .onTapGesture {
                            SoundManager.shared.playWhoosh()
                            withAnimation(.easeInOut(duration: 0.8)) { spinningPlanet = i }
                            Task {
                                try? await Task.sleep(nanoseconds: 850_000_000)
                                spinningPlanet = nil
                            }
                        }
                }

                VStack {
                    MiniAppTitle(text: "Space", subtitle: phase == .landed ? "Landed on the Moon!" : "Click the rocket, or press Space, to launch")
                    Spacer()
                }

                if phase == .counting {
                    Text("\(count)")
                        .font(.system(size: 130, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .id(count)
                        .transition(.scale.combined(with: .opacity))
                }

                if phase == .landed {
                    Text("👨‍🚀")
                        .font(.system(size: 76))
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.3)
                        .transition(.scale)
                }

                VStack(spacing: -8) {
                    Text("🚀")
                        .font(.system(size: 92))
                        .rotationEffect(.degrees(-45))
                    if phase == .flying {
                        Text("🔥").font(.system(size: 42)).offset(x: -26)
                    }
                }
                .position(x: geo.size.width * 0.5,
                          y: geo.size.height * (0.78 - 0.62 * rocketY))
                .opacity(phase == .landed ? 0 : 1)
                .onTapGesture { launch() }
            }
            .onAppear { contentSize = geo.size }
            .onChange(of: geo.size) { contentSize = $0 }
            .onDisappear { starTask?.cancel() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "space") { press in
            if press.isSpace { launch() }
        }
    }

    private func launch() {
        guard phase == .ready else { return }
        phase = .counting
        count = 3
        Task {
            for n in stride(from: 3, through: 1, by: -1) {
                withAnimation(.spring(duration: 0.3)) { count = n }
                SoundManager.shared.playKeypadTone(digit: n)
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
            phase = .flying
            SoundManager.shared.playWhoosh()
            let width = max(contentSize.width, 40)
            starTask = Task {
                while !Task.isCancelled {
                    stars.append(Star(x: CGFloat.random(in: 10...(width - 10)),
                                      size: CGFloat.random(in: 12...26), duration: 0.9))
                    if stars.count > 60 { stars.removeFirst(stars.count - 60) }
                    try? await Task.sleep(nanoseconds: 80_000_000)
                }
            }
            withAnimation(.easeIn(duration: 2.8)) { rocketY = 1 }
            try? await Task.sleep(nanoseconds: 2_900_000_000)
            starTask?.cancel()
            withAnimation(.spring(duration: 0.4)) { phase = .landed }
            SoundManager.shared.playBabble()
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            rocketY = 0
            withAnimation { phase = .ready }
        }
    }
}

// MARK: - Garden

/// Click the dirt to plant. Water everything to make the garden wiggle
/// and bring the butterflies.
struct GardenMiniApp: View {
    private struct Plant: Identifiable {
        let id = UUID()
        let flower: String
        let position: CGPoint
        var grown = false
    }

    private struct Visitor: Identifiable {
        let id = UUID()
        let emoji: String
        let y: CGFloat
        let leftToRight: Bool
    }

    @State private var plants: [Plant] = []
    @State private var visitors: [Visitor] = []
    @State private var raining = false
    @State private var wiggle = false
    @State private var rain: [UUID] = []

    private let flowers = ["🌷", "🌻", "🌹", "🌸", "🌼", "🌺", "🍄", "🥕"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.45, green: 0.85, blue: 0.95), Color(red: 0.45, green: 0.75, blue: 0.4)],
                               startPoint: .top, endPoint: .bottom)
                Rectangle()
                    .fill(Color(red: 0.45, green: 0.3, blue: 0.15))
                    .frame(height: geo.size.height * 0.62)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.69)

                Text("☀️")
                    .font(.system(size: 60))
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.16)

                ForEach(plants) { plant in
                    Text(plant.grown ? plant.flower : "🌱")
                        .font(.system(size: plant.grown ? 56 : 36))
                        .rotationEffect(.degrees(wiggle ? 8 : -8))
                        .position(plant.position)
                        .transition(.scale)
                }

                ForEach(visitors) { visitor in
                    FlyAcross(emoji: visitor.emoji, y: visitor.y, leftToRight: visitor.leftToRight, width: geo.size.width)
                }

                if raining {
                    ForEach(rain, id: \.self) { _ in
                        FallingText(text: "💧", x: CGFloat.random(in: 10...geo.size.width - 10),
                                    size: 22, duration: Double.random(in: 0.8...1.4), height: geo.size.height)
                    }
                }

                VStack {
                    MiniAppTitle(text: "Garden", subtitle: "Click the dirt to plant. W or Space waters.")
                    Spacer()
                    MiniAppRoundButton(emoji: "🚿", tint: .blue.opacity(0.7), size: 64) { water() }
                        .padding(.bottom, 20)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    guard value.location.y > geo.size.height * 0.38 else { return }
                    plant(at: value.location, width: geo.size.width)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "garden") { press in
            if press.isSpace || press.letter == "W" { water() }
        }
    }

    private func plant(at point: CGPoint, width: CGFloat) {
        let new = Plant(flower: flowers.randomElement()!, position: point)
        SoundManager.shared.playTouchTone(normalizedX: point.x / max(width, 1))
        withAnimation(.spring(duration: 0.3)) {
            plants.append(new)
            if plants.count > 30 { plants.removeFirst() }
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            withAnimation(.spring(duration: 0.4)) {
                if let i = plants.firstIndex(where: { $0.id == new.id }) { plants[i].grown = true }
            }
            SoundManager.shared.playPop()
        }
    }

    private func water() {
        guard !raining else { return }
        raining = true
        SoundManager.shared.playWhoosh()
        rain = (0..<40).map { _ in UUID() }
        withAnimation(.easeInOut(duration: 0.25).repeatCount(7, autoreverses: true)) { wiggle.toggle() }
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(.spring(duration: 0.4)) {
                for i in plants.indices { plants[i].grown = true }
            }
            visitors.append(Visitor(emoji: ["🦋", "🐝", "🐞", "🐦"].randomElement()!,
                                    y: CGFloat.random(in: 140...260), leftToRight: Bool.random()))
            if visitors.count > 6 { visitors.removeFirst() }
            SoundManager.shared.playBabble()
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            raining = false
            rain = []
        }
    }

    private struct FlyAcross: View {
        let emoji: String
        let y: CGFloat
        let leftToRight: Bool
        let width: CGFloat
        @State private var x: CGFloat = 0

        var body: some View {
            Text(emoji)
                .font(.system(size: 40))
                .scaleEffect(x: leftToRight ? 1 : -1)
                .position(x: x, y: y)
                .onAppear {
                    x = leftToRight ? -40 : width + 40
                    withAnimation(.linear(duration: 4)) { x = leftToRight ? width + 40 : -40 }
                }
        }
    }
}
