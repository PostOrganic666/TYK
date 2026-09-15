import SwiftUI
import Combine

/// Shared pieces for the pretend-Mac apps. Every app view is shown inside
/// a fake macOS window sized by its ComputerApp.defaultSize and receives
/// the desktop's ComputerInput as an environment object.
enum MiniAppLayout {
    /// Keep app content this far from the fake window edges.
    static let inset: CGFloat = 16
}

/// Title used at the top of most apps.
struct MiniAppTitle: View {
    let text: String
    var subtitle: String? = nil
    var color: Color = .white

    var body: some View {
        VStack(spacing: 2) {
            Text(text)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(color.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 24)
    }
}

/// A big round button with an emoji or symbol.
struct MiniAppRoundButton: View {
    var emoji: String? = nil
    var symbol: String? = nil
    var tint: Color = .white.opacity(0.18)
    var size: CGFloat = 60
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(tint)
                if let emoji {
                    Text(emoji).font(.system(size: size * 0.5))
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: size, height: size)
            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 2))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// Buttons shrink while pressed.
struct SquishyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Fires on mouse-down, not release: pianos and drums must feel instant.
struct PressDownModifier: ViewModifier {
    let action: () -> Void
    @State private var down = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(down ? 0.94 : 1.0)
            .animation(.spring(duration: 0.15), value: down)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !down {
                            down = true
                            action()
                        }
                    }
                    .onEnded { _ in down = false }
            )
    }
}

extension View {
    func onPressDown(_ action: @escaping () -> Void) -> some View {
        modifier(PressDownModifier(action: action))
    }

    /// Subscribe to typed keys while this app is the focused window.
    func onAppKey(appID: String, perform: @escaping (ComputerInput.KeyPress) -> Void) -> some View {
        onReceive(ComputerInput.shared.keyDown) { press in
            if ComputerInput.shared.focusedAppID == appID { perform(press) }
        }
    }
}

/// Confetti burst for "you did it" moments.
struct ConfettiBurst: View {
    let id: Int
    var emojis: [String] = ["🎉", "✨", "⭐", "🎊", "💛"]

    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                ConfettiPiece(emoji: emojis[i % emojis.count], seed: i, trigger: id)
            }
        }
        .allowsHitTesting(false)
    }

    private struct ConfettiPiece: View {
        let emoji: String
        let seed: Int
        let trigger: Int
        @State private var flown = false

        var body: some View {
            let angle = Double(seed) / 14.0 * .pi * 2
            let distance: CGFloat = 120 + CGFloat(seed % 4) * 30
            Text(emoji)
                .font(.system(size: 28))
                .offset(x: flown ? cos(angle) * distance : 0, y: flown ? sin(angle) * distance : 0)
                .opacity(flown ? 0 : 1)
                .onAppear { withAnimation(.easeOut(duration: 1.1)) { flown = true } }
                .id(trigger)
        }
    }
}

/// A friendly bubble of text that pops in.
struct PopBubble: View {
    let text: String
    @State private var shown = false

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.black.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white))
            .scaleEffect(shown ? 1 : 0.2)
            .opacity(shown ? 1 : 0)
            .onAppear { withAnimation(.spring(duration: 0.35)) { shown = true } }
    }
}

/// Text that falls from the top of its container once.
struct FallingText: View {
    let text: String
    let x: CGFloat
    let size: CGFloat
    let duration: Double
    let height: CGFloat
    @State private var y: CGFloat = -60

    var body: some View {
        Text(text)
            .font(.system(size: size))
            .position(x: x, y: y)
            .onAppear { withAnimation(.linear(duration: duration)) { y = height + 60 } }
    }
}

/// The pretend contacts, shared by Messages, FaceTime, and Mail. The
/// subtitle and preview lines are for the adults watching over a
/// shoulder. Keep every one of these exactly as written.
struct PhoneContact: Identifiable, Equatable {
    let face: String
    let name: String
    let title: String
    let preview: String

    var id: String { name }

    static let all = [
        PhoneContact(face: "🐻", name: "Barry", title: "Chief Snack Officer", preview: "URGENT: we are out of goldfish"),
        PhoneContact(face: "🐶", name: "Biscuit", title: "Emotional Support Coordinator", preview: "who's a good boy? asking for me"),
        PhoneContact(face: "🐱", name: "Deborah", title: "Has declined your last 6 calls", preview: "we need to talk about the crayons."),
        PhoneContact(face: "🦁", name: "Dave", title: "Regional Manager, Jungle District", preview: "per my last roar"),
        PhoneContact(face: "🐸", name: "Gary", title: "Pond HOA President", preview: "pond meeting moved to 3pm"),
        PhoneContact(face: "🐵", name: "Kevin", title: "DO NOT lend money", preview: "can i borrow $5, it's for bananas"),
        PhoneContact(face: "🦊", name: "Francine", title: "Knows what you did", preview: "i saw everything."),
        PhoneContact(face: "🐷", name: "Sir Oinksalot", title: "Bedtime Attorney at Law", preview: "my client denies eating the homework"),
        PhoneContact(face: "🐢", name: "Speedy", title: "Returns calls in 3–5 business days", preview: "omw (eta thursday)"),
        PhoneContact(face: "🦆", name: "The Duck", title: "It's always quack with this one", preview: "quack"),
    ]
}
