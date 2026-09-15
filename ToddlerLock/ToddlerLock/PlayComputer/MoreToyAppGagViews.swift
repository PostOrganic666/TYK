import SwiftUI

// MARK: - Mail

/// A two-column inbox from the animal friends. Subject lines are for the
/// adults. Replying sends a cookie and gets an out-of-office back.
struct MailMiniApp: View {
    private struct Email: Identifiable {
        let id = UUID()
        let face: String
        let from: String
        let subject: String
        let body: String
    }

    private let inbox = [
        Email(face: "🐻", from: "Barry", subject: "URGENT: goldfish inventory critical", body: "We are down to four. Four. I counted twice.\n\n🐟🐟🐟🐟"),
        Email(face: "🦒", from: "Gerald", subject: "Re: Re: Re: Re: nap", body: "Per my previous email, I did not agree to a nap.\n\n😤"),
        Email(face: "🐸", from: "Pond HOA", subject: "Lily pad assessment overdue", body: "Your lily pad fee is 30 days past due. Croak at your earliest convenience.\n\n🪷"),
        Email(face: "🐱", from: "Deborah", subject: "(no subject)", body: ".\n\n🐾"),
        Email(face: "🦉", from: "Auntie Owl", subject: "You up?", body: "It is 3 AM. So are you. Coincidence?\n\n🌙"),
        Email(face: "🧦", from: "Sock Committee", subject: "Where is the other one", body: "We have questions. We have had questions since Tuesday.\n\n🧦❓"),
        Email(face: "🦁", from: "Dave", subject: "Q3 roar targets", body: "Let's circle back. Loudly.\n\n📈"),
        Email(face: "🐵", from: "Kevin", subject: "quick favor", body: "it's about the $5. and also another $5.\n\n🍌"),
        Email(face: "🐢", from: "Speedy", subject: "RE: your message from March", body: "Just seeing this now. Will respond by winter.\n\n🐢"),
        Email(face: "😴", from: "Nap Department", subject: "Your nap has been rescheduled", body: "New time: never.\nReason: you.\n\n🛏️"),
    ]

    @State private var selected: UUID?
    @State private var replied = false

    private var selectedEmail: Email? { inbox.first { $0.id == selected } }

    var body: some View {
        HStack(spacing: 0) {
            list
                .frame(width: 250)
                .background(Color(red: 0.05, green: 0.2, blue: 0.4))
            Divider()
            Group {
                if let email = selectedEmail {
                    detail(email)
                } else {
                    Text("Select a message")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { if selected == nil { selected = inbox.first?.id } }
        .onAppKey(appID: "mail") { press in
            if press.isReturn { reply() }
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            MiniAppTitle(text: "Inbox", subtitle: "999+ unread. Growing.")
                .padding(.bottom, 8)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(inbox) { email in
                        Button {
                            SoundManager.shared.playPop()
                            replied = false
                            withAnimation(.spring(duration: 0.3)) { selected = email.id }
                        } label: {
                            HStack(spacing: 10) {
                                Text(email.face)
                                    .font(.system(size: 30))
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.white.opacity(0.12)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(email.from)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(email.subject)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 4)
                                if selected != email.id {
                                    Circle().fill(.blue).frame(width: 8, height: 8)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(selected == email.id ? Color.white.opacity(0.14) : Color.clear))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
        }
    }

    private func detail(_ email: Email) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(email.face).font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(email.from).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("To: You").font(.system(size: 12, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.top, 16)
            Text(email.subject)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(email.body)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            if replied {
                Text("You: 🍪\n\(email.from): Out of office until nap ends.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    reply()
                } label: {
                    Text("Reply 🍪")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.blue))
                }
                .buttonStyle(SquishyButtonStyle())
                Text("Return sends it too")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 22)
    }

    private func reply() {
        guard selectedEmail != nil, !replied else { return }
        SoundManager.shared.playWhoosh()
        withAnimation { replied = true }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            SoundManager.shared.playBabble()
        }
    }
}

// MARK: - Treats

/// Decorate a cake, add candles, blow them out, eat it, repeat.
struct TreatsMiniApp: View {
    private struct Topping: Identifiable {
        let id = UUID()
        let emoji: String
        let position: CGPoint
    }

    @State private var toppings: [Topping] = []
    @State private var candles = 0
    @State private var lit = true
    @State private var bites = 0
    @State private var confettiID = 0
    @State private var showConfetti = false

    private let sprinkles = ["🍓", "🍒", "🍬", "🍫", "🫐", "⭐", "🍭", "🌈"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.98, green: 0.55, blue: 0.7), Color(red: 0.62, green: 0.3, blue: 0.75)],
                               startPoint: .top, endPoint: .bottom)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            decorate(at: value.location, width: geo.size.width)
                        }
                    )

                VStack(spacing: 12) {
                    MiniAppTitle(text: "Treats", subtitle: lit && candles > 0 ? "Make a wish!" : "Click the cake to decorate. C, B, E work too.")
                    Spacer()
                }

                // Candles
                HStack(spacing: 6) {
                    ForEach(0..<candles, id: \.self) { _ in
                        Text(lit ? "🕯️" : "💨").font(.system(size: 30))
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.36)

                Text(bites >= 3 ? "🍽️" : bites > 0 ? "🍰" : "🎂")
                    .font(.system(size: 170 - CGFloat(bites) * 26))
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                    .allowsHitTesting(false)

                ForEach(toppings) { topping in
                    Text(topping.emoji)
                        .font(.system(size: 30))
                        .position(topping.position)
                        .transition(.scale)
                        .allowsHitTesting(false)
                }

                if showConfetti {
                    ConfettiBurst(id: confettiID)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.45)
                }

                VStack {
                    Spacer()
                    HStack(spacing: 18) {
                        MiniAppRoundButton(emoji: "🕯️", tint: .orange.opacity(0.7), size: 62) { addCandle() }
                        MiniAppRoundButton(emoji: "💨", tint: .cyan.opacity(0.7), size: 62) { blow() }
                        MiniAppRoundButton(emoji: "😋", tint: .yellow.opacity(0.7), size: 62) { eat() }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "treats") { press in
            switch press.letter {
            case "C": addCandle()
            case "B": blow()
            case "E": eat()
            default: break
            }
        }
    }

    private func decorate(at point: CGPoint, width: CGFloat) {
        SoundManager.shared.playTouchTone(normalizedX: point.x / max(width, 1))
        withAnimation(.spring(duration: 0.3)) {
            toppings.append(Topping(emoji: sprinkles.randomElement()!, position: point))
            if toppings.count > 40 { toppings.removeFirst() }
        }
    }

    private func addCandle() {
        guard candles < 8 else { return }
        candles += 1
        lit = true
        SoundManager.shared.playPop()
    }

    private func blow() {
        guard candles > 0, lit else { return }
        lit = false
        confettiID += 1
        showConfetti = true
        SoundManager.shared.playWhoosh()
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            SoundManager.shared.playBabble()
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            showConfetti = false
        }
    }

    private func eat() {
        SoundManager.shared.playPop()
        withAnimation(.spring(duration: 0.3)) {
            if bites >= 3 {
                bites = 0
                toppings.removeAll()
                candles = 0
                lit = true
            } else {
                bites += 1
                if !toppings.isEmpty { toppings.removeFirst(min(toppings.count, 10)) }
            }
        }
    }
}

// MARK: - Taxes

/// Form 1040-EZ-PZ. Click each line to fill it with numbers. File it.
struct TaxesMiniApp: View {
    private struct Line: Identifiable {
        let id = UUID()
        let label: String
        var value: String = "—"
    }

    @State private var lines = [
        Line(label: "Income (goldfish)"),
        Line(label: "Dependents (stuffed animals)"),
        Line(label: "Naps skipped"),
        Line(label: "Crayons eaten"),
        Line(label: "Hours of sleep"),
        Line(label: "Adjusted gross snacks"),
    ]
    @State private var filed = false
    @State private var verdict = ""

    private let verdicts = [
        "Refund: one (1) nap",
        "You owe: 3 hugs",
        "Refund: 12 goldfish",
        "Audit scheduled. Bring snacks.",
        "You owe: nothing. You're a baby.",
    ]

    var body: some View {
        ZStack {
            Color(red: 0.93, green: 0.92, blue: 0.88)

            VStack(spacing: 8) {
                MiniAppTitle(text: "Form 1040-EZ-PZ", subtitle: "Toddler Income Tax Return", color: .black.opacity(0.8))
                    .padding(.bottom, 8)

                ForEach(lines) { line in
                    Button {
                        fill(line.id)
                    } label: {
                        HStack {
                            Text(line.label)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.75))
                            Spacer()
                            Text(line.value)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundStyle(.blue)
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black.opacity(0.15)))
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
                .padding(.horizontal, 20)

                Spacer()

                ZStack {
                    Button {
                        file()
                    } label: {
                        Text("FILE")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(.black.opacity(0.75)))
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .opacity(filed ? 0 : 1)

                    if filed {
                        VStack(spacing: 6) {
                            Text("APPROVED")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: 4))
                                .rotationEffect(.degrees(-12))
                            Text(verdict)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.8))
                        }
                        .transition(.scale.combined(with: .opacity))
                        .onTapGesture { withAnimation { filed = false } }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "taxes") { press in
            if press.isReturn { file() }
        }
    }

    private func fill(_ id: UUID) {
        guard let i = lines.firstIndex(where: { $0.id == id }) else { return }
        SoundManager.shared.playKeypadTone(digit: Int.random(in: 0...9))
        let value = ["0", "3", "7", "12", "41", "99", "∞", "-2", "1,000,000", "½"].randomElement()!
        withAnimation(.spring(duration: 0.3)) { lines[i].value = value }
    }

    private func file() {
        verdict = verdicts.randomElement()!
        SoundManager.shared.playRing()
        withAnimation(.spring(duration: 0.4)) { filed = true }
    }
}

// MARK: - Laundry

/// Match the socks. They never match. Except when they do.
struct LaundryMiniApp: View {
    private struct Sock: Identifiable {
        let id = UUID()
        let hue: Double
        let emoji: String
    }

    @State private var socks: [Sock] = []
    @State private var picked: UUID?
    @State private var verdict = "Click two socks"
    @State private var spinning = false
    @State private var confettiID = 0
    @State private var showConfetti = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.2, green: 0.7, blue: 0.7), Color(red: 0.15, green: 0.4, blue: 0.85)],
                           startPoint: .top, endPoint: .bottom)

            VStack(spacing: 14) {
                MiniAppTitle(text: "Laundry", subtitle: "Odd socks: ∞. Space washes.")
                Text(verdict)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .id(verdict)
                    .transition(.scale)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(socks) { sock in
                        Text(sock.emoji)
                            .font(.system(size: 46))
                            .hueRotation(.degrees(sock.hue))
                            .scaleEffect(picked == sock.id ? 1.3 : 1)
                            .rotationEffect(.degrees(spinning ? 360 : 0))
                            .frame(height: 64)
                            .contentShape(Rectangle())
                            .onTapGesture { pick(sock) }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                ZStack {
                    if showConfetti { ConfettiBurst(id: confettiID, emojis: ["🧦", "🎉", "✨"]) }
                    MiniAppRoundButton(symbol: "arrow.triangle.2.circlepath", tint: .white.opacity(0.25), size: 64) { wash() }
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { if socks.isEmpty { shuffle() } }
        .onAppKey(appID: "laundry") { press in
            if press.isSpace { wash() }
        }
    }

    private func shuffle() {
        socks = (0..<16).map { _ in Sock(hue: Double.random(in: 0...360), emoji: ["🧦", "🧦", "🧦", "🧤"].randomElement()!) }
    }

    private func pick(_ sock: Sock) {
        SoundManager.shared.playPop()
        guard let first = picked, first != sock.id else {
            withAnimation(.spring(duration: 0.25)) { picked = sock.id }
            return
        }
        let match = Int.random(in: 0..<8) == 0
        withAnimation(.spring(duration: 0.3)) {
            picked = nil
            verdict = match ? "A MATCH! Frame it." : ["Not a pair.", "Close. No.", "One is a mitten.", "Nope.", "Never seen these before."].randomElement()!
        }
        if match {
            confettiID += 1
            showConfetti = true
            SoundManager.shared.playRing()
            Task {
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                showConfetti = false
            }
        } else {
            SoundManager.shared.playWhoosh()
        }
    }

    private func wash() {
        SoundManager.shared.playWhoosh()
        withAnimation(.easeInOut(duration: 0.8)) { spinning = true }
        Task {
            try? await Task.sleep(nanoseconds: 850_000_000)
            spinning = false
            withAnimation { shuffle(); verdict = "Washed. Still odd." }
        }
    }
}

// MARK: - Calculator

/// A calculator that answers every question with snacks.
struct CalculatorMiniApp: View {
    @State private var display = "0"
    @State private var answered = false

    private let keys = [["7", "8", "9", "÷"], ["4", "5", "6", "×"], ["1", "2", "3", "−"], ["C", "0", "=", "+"]]
    private let answers = ["🍪 × 3", "∞", "42", "a lot", "yes", "🍌🍌🍌", "NaN (Not a Nap)", "7 (ish)", "🐘 tons", "one more"]

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 12) {
                MiniAppTitle(text: "Calculator")
                Text(display)
                    .font(.system(size: answered ? 40 : 54, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 22)
                    .frame(height: 70)

                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { key in
                            Button {
                                press(key)
                            } label: {
                                Text(key)
                                    .font(.system(size: 28, weight: .medium, design: .rounded))
                                    .foregroundStyle(key == "C" ? .black : .white)
                                    .frame(width: 68, height: 68)
                                    .background(Circle().fill(color(for: key)))
                            }
                            .buttonStyle(SquishyButtonStyle())
                        }
                    }
                }
                Spacer().frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppKey(appID: "calculator") { keyPress in
            if keyPress.isDelete { press("C"); return }
            if keyPress.isReturn { press("="); return }
            guard let c = keyPress.characters?.first else { return }
            switch c {
            case "0"..."9": press(String(c))
            case "+": press("+")
            case "-": press("−")
            case "*": press("×")
            case "/": press("÷")
            case "=": press("=")
            default: break
            }
        }
    }

    private func color(for key: String) -> Color {
        switch key {
        case "C": return Color(white: 0.75)
        case "÷", "×", "−", "+", "=": return .orange
        default: return Color(white: 0.25)
        }
    }

    private func press(_ key: String) {
        switch key {
        case "C":
            display = "0"
            answered = false
            SoundManager.shared.playWhoosh()
        case "=":
            display = answers.randomElement()!
            answered = true
            SoundManager.shared.playRing()
        default:
            SoundManager.shared.playKeypadTone(digit: Int(key) ?? 5)
            if answered || display == "0" { display = ""; answered = false }
            if display.count < 12 { display += key }
        }
    }
}
