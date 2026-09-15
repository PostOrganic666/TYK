import AVFoundation
import SwiftUI

/// FaceTime-style video call with a talking, blinking animal friend.
/// Ported from VideoCallMiniApp.swift (iOS). The small self-view shows
/// the real front camera only when a parent already granted access;
/// otherwise a placeholder. Nothing is recorded or transmitted, and this
/// view never prompts for camera access.
struct FaceTimeToyApp: View {
    private enum Phase { case picking, ringing, talking }

    @StateObject private var camera = PlayCameraController()
    @State private var phase: Phase = .picking
    @State private var contact = PhoneContact.all[0]
    @State private var talking = false
    @State private var blink = false
    @State private var bubble: String?
    @State private var muted = false
    @State private var callTask: Task<Void, Never>?

    private let lines = [
        "Can you see me?",
        "You're on mute. Still.",
        "Is that a crayon in your nose?",
        "Say hi to Grandma!",
        "Wait, where did you go?",
        "I can only see the ceiling.",
        "Peekaboo!",
        "Show me the dog!",
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        ZStack {
            Color.black

            switch phase {
            case .picking:
                picker
            case .ringing, .talking:
                callScreen
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Never prompt inside a toddler session: only use the camera
            // if a parent already granted it.
            if PlayCameraController.accessAlreadyGranted {
                camera.start(allowPrompt: false)
            }
        }
        .onDisappear {
            callTask?.cancel()
            camera.stop()
        }
    }

    private var picker: some View {
        VStack(spacing: 10) {
            MiniAppTitle(text: "FaceTime", subtitle: "Who do you want to call?")
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(PhoneContact.all) { friend in
                        Button {
                            start(friend)
                        } label: {
                            VStack(spacing: 6) {
                                Text(friend.face)
                                    .font(.system(size: 48))
                                    .frame(width: 78, height: 78)
                                    .background(Circle().fill(.white.opacity(0.12)))
                                Text(friend.name)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, MiniAppLayout.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var callScreen: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.15, green: 0.25, blue: 0.2), .black],
                               startPoint: .top, endPoint: .bottom)

                ZStack {
                    Text(contact.face)
                        .font(.system(size: 190))
                        .scaleEffect(talking ? 1.06 : 1)
                        .rotationEffect(.degrees(talking ? 3 : -3))
                        .animation(phase == .talking ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true) : .default, value: talking)
                    if blink {
                        Text("✨").font(.system(size: 46)).offset(x: 78, y: -70)
                            .transition(.scale)
                    }
                    if let bubble {
                        PopBubble(text: bubble)
                            .offset(y: -150)
                            .id(bubble)
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                .onTapGesture {
                    SoundManager.shared.playBabble()
                    say(lines.randomElement()!)
                }

                VStack {
                    Text(phase == .ringing ? "Calling \(contact.name)…" : contact.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 16)
                    Text(contact.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    Spacer()
                }

                ZStack {
                    if PlayCameraController.accessAlreadyGranted, camera.state == .running {
                        CameraPreview(session: camera.session)
                    } else {
                        Color(white: 0.15)
                        Text("🧒").font(.system(size: 54))
                    }
                    if muted {
                        VStack { Spacer(); HStack { Spacer(); Text("🔇").font(.system(size: 18)).padding(6) } }
                    }
                }
                .frame(width: 100, height: 136)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.5), lineWidth: 2))
                .position(x: geo.size.width - 70, y: geo.size.height * 0.72)

                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        MiniAppRoundButton(emoji: muted ? "🔇" : "🎤", tint: .white.opacity(0.2), size: 58) {
                            muted.toggle()
                            SoundManager.shared.playPop()
                            say(muted ? "You're on mute." : "There you are!")
                        }
                        MiniAppRoundButton(symbol: "phone.down.fill", tint: .red, size: 66) { end() }
                        MiniAppRoundButton(symbol: "arrow.triangle.2.circlepath", tint: .white.opacity(0.2), size: 58) {
                            let next = PhoneContact.all.filter { $0 != contact }.randomElement()!
                            start(next)
                        }
                    }
                    .padding(.bottom, MiniAppLayout.inset)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func start(_ friend: PhoneContact) {
        callTask?.cancel()
        contact = friend
        phase = .ringing
        talking = false
        bubble = nil
        callTask = Task {
            for _ in 0..<2 {
                guard !Task.isCancelled else { return }
                SoundManager.shared.playRing()
                try? await Task.sleep(nanoseconds: 1_300_000_000)
            }
            guard !Task.isCancelled else { return }
            phase = .talking
            talking = true
            say(["Hi!!", "Hello there!", "Peekaboo!"].randomElement()!)
            while !Task.isCancelled {
                SoundManager.shared.playBabble()
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(.easeInOut(duration: 0.1)) { blink = true }
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation { blink = false }
                if Int.random(in: 0..<3) == 0 { say(lines.randomElement()!) }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(duration: 0.3)) { bubble = text }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation { if bubble == text { bubble = nil } }
        }
    }

    private func end() {
        callTask?.cancel()
        callTask = nil
        SoundManager.shared.playWhoosh()
        talking = false
        withAnimation(.spring(duration: 0.3)) { phase = .picking }
    }
}

/// Bridges the AppKit camera preview layer into SwiftUI, mirrored like a
/// selfie camera.
private struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView(session: session)
        view.setMirrored(true)
        return view
    }

    func updateNSView(_ nsView: CameraPreviewView, context: Context) {}
}
