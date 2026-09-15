import SwiftUI

/// Pretend Messages: a left column of animal friends (PhoneContact.all)
/// and a right column chat thread. Ported from PlayPhoneView.swift's
/// FakeMessagesApp / FakeChatView (iOS), rebuilt as a two-pane Mac
/// window. Typing on the real keyboard writes the draft; the on-screen
/// big-letter keyboard still works too. Nothing is sent anywhere.
struct MessagesToyApp: View {
    private struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let fromMe: Bool
    }

    @State private var selected: PhoneContact = PhoneContact.all[0]
    @State private var threads: [String: [ChatMessage]] = [:]
    @State private var draft = ""
    @State private var replyTask: Task<Void, Never>?

    private let replies = [
        "k",
        "The duck says hi.",
        "Let's circle back after snack.",
        "I've escalated this to Grandma.",
        "Per my last babble…",
        "New crayon, who dis?",
        "Can't talk. Hiding from bedtime.",
        "🍪🍪🍪",
        "This could have been a nap.",
        "Noted. Filing under snacks.",
        "Adding it to the agenda. The agenda is snacks.",
    ]

    private let keyRows = ["ABCDEFG", "HIJKLMN", "OPQRSTU", "VWXYZ"]
    private let emojiKeys = ["❤️", "😂", "🎉", "🐶", "🍪"]

    var body: some View {
        HStack(spacing: 0) {
            contactList
                .frame(width: 260)
            Divider()
            chatPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(LinearGradient(colors: [Color(red: 0.08, green: 0.12, blue: 0.25), .black],
                                    startPoint: .top, endPoint: .bottom))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { seedThread(for: selected) }
        .onDisappear { replyTask?.cancel() }
        .onAppKey(appID: "messages") { press in
            if press.isReturn {
                send()
            } else if press.isDelete {
                if !draft.isEmpty { draft.removeLast() }
            } else if press.isSpace {
                appendToDraft(" ")
            } else if let c = press.characters?.first, c.isLetter || c.isNumber {
                appendToDraft(String(c))
            }
        }
    }

    private var contactList: some View {
        VStack(spacing: 0) {
            MiniAppTitle(text: "Messages", color: .white)
                .padding(.bottom, 10)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(PhoneContact.all) { contact in
                        Button {
                            SoundManager.shared.playPop()
                            select(contact)
                        } label: {
                            HStack(spacing: 10) {
                                Text(contact.face)
                                    .font(.system(size: 30))
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(.white.opacity(contact.id == selected.id ? 0.25 : 0.1)))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(contact.preview)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(contact.id == selected.id ? 0.1 : 0)))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, MiniAppLayout.inset)
            }
        }
    }

    private var chatPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(selected.face).font(.system(size: 30))
                VStack(alignment: .leading, spacing: 1) {
                    Text(selected.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(selected.title)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(threads[selected.id] ?? []) { message in
                            bubble(message)
                        }
                        Color.clear.frame(height: 2).id("chatEnd")
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: threads[selected.id]?.count ?? 0) { _ in
                    withAnimation { proxy.scrollTo("chatEnd") }
                }
            }

            HStack(spacing: 10) {
                Text(draft.isEmpty ? " " : draft)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white.opacity(0.12)))
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(draft.isEmpty ? .gray : .green)
                }
                .buttonStyle(SquishyButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            VStack(spacing: 6) {
                ForEach(keyRows, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(Array(row), id: \.self) { letter in
                            key(String(letter))
                        }
                    }
                }
                HStack(spacing: 8) {
                    ForEach(emojiKeys, id: \.self) { emoji in
                        Button {
                            SoundManager.shared.playPop()
                            appendToDraft(emoji)
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .frame(width: 44, height: 34)
                                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.14)))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, MiniAppLayout.inset)
        }
    }

    private func key(_ letter: String) -> some View {
        Button {
            SoundManager.shared.playKeypadTone(digit: Int(letter.unicodeScalars.first?.value ?? 65))
            appendToDraft(letter)
        } label: {
            Text(letter)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.14)))
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.fromMe { Spacer(minLength: 50) }
            Text(message.text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(message.fromMe ? Color.blue : Color.white.opacity(0.16))
                )
            if !message.fromMe { Spacer(minLength: 50) }
        }
    }

    private func select(_ contact: PhoneContact) {
        selected = contact
        seedThread(for: contact)
    }

    private func seedThread(for contact: PhoneContact) {
        guard threads[contact.id] == nil else { return }
        threads[contact.id] = [
            ChatMessage(text: contact.preview, fromMe: false),
            ChatMessage(text: "😂", fromMe: true),
            ChatMessage(text: replies.randomElement() ?? "k", fromMe: false),
        ]
    }

    private func appendToDraft(_ text: String) {
        if draft.count < 24 {
            draft += text
        }
    }

    private func send() {
        guard !draft.isEmpty else { return }
        let contactID = selected.id
        threads[contactID, default: []].append(ChatMessage(text: draft, fromMe: true))
        draft = ""
        SoundManager.shared.playWhoosh()

        replyTask?.cancel()
        replyTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            SoundManager.shared.playBabble()
            threads[contactID, default: []].append(ChatMessage(text: replies.randomElement() ?? "k", fromMe: false))
        }
    }
}
