import SwiftUI
import AppKit
import CoreGraphics

struct SettingsView: View {
    @State private var selectedMode = SettingsStore.shared.selectedMode
    @State private var soundEnabled = SettingsStore.shared.soundEnabled
    @State private var maxVolume = SettingsStore.shared.maxVolume
    @State private var sessionLimitMinutes = SettingsStore.shared.sessionLimitMinutes
    @State private var exitKeyCode = SettingsStore.shared.exitKeyCode
    @State private var exitModifiers = SettingsStore.shared.exitModifiers
    @State private var unlockGate = SettingsStore.shared.unlockGate
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordError: String?

    var onLockNow: (() -> Void)?

    static let contentSize = NSSize(width: 720, height: 520)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                modeGrid
                HStack(alignment: .top, spacing: 14) {
                    SettingsPanel(title: "Звук и время") { playPanel }
                    SettingsPanel(title: "Что будет происходить") {
                        Text(selectedMode.blurb)
                            .font(.system(size: 14, weight: .medium))
                        Text(selectedMode.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                SettingsPanel(title: "Выход для взрослого") { exitPanel }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Divider()
            HStack {
                Text("Во время игры системные сочетания, Dock и жесты заблокированы.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: lockNow) {
                    Label("Запустить «\(selectedMode.rawValue)»", systemImage: "lock.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .controlSize(.small)
        .frame(minWidth: 680, minHeight: 500)
        .background(WindowConfigurator(contentSize: Self.contentSize,
                                       minSize: NSSize(width: 680, height: 500)))
    }

    private var modeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 4), spacing: 9) {
            ForEach(PlayModeType.featured, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { selectedMode = mode }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: mode.symbolName)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(selectedMode == mode ? .accentColor : .primary)
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selectedMode == mode ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.045))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selectedMode == mode ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: selectedMode == mode ? 2 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var playPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingRow(label: "Звук") {
                Toggle("Включён", isOn: $soundEnabled).toggleStyle(.checkbox)
            }
            SettingRow(label: "Громкость") {
                Slider(value: $maxVolume, in: 0.1...1.0, step: 0.1) { editing in
                    if !editing && soundEnabled {
                        SampledInstrument.shared.volume = Float(maxVolume) * 0.75
                        SampledInstrument.shared.play(scaleIndex: 4, velocity: 68)
                    }
                }
                .frame(maxWidth: 150)
                Text("\(Int((maxVolume * 100).rounded()))%")
                    .font(.callout.monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(width: 38, alignment: .trailing)
            }
            SettingRow(label: "Перерыв") {
                Picker("Перерыв", selection: $sessionLimitMinutes) {
                    Text("Выкл.").tag(0)
                    ForEach([5, 10, 15, 20, 30, 45, 60], id: \.self) { Text("\($0) мин").tag($0) }
                }
                .labelsHidden()
                .frame(width: 110)
            }
        }
    }

    private var exitPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 18) {
                SettingRow(label: "Комбинация") {
                    ShortcutRecorderView(keyCode: $exitKeyCode, modifiers: $exitModifiers)
                        .frame(width: 155, height: 26)
                }
                SettingRow(label: "Затем") {
                    Picker("Затем", selection: $unlockGate) {
                        ForEach(UnlockGate.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            }
            if unlockGate == .password {
                HStack {
                    SecureField(KeychainManager.hasPassword ? "Новый пароль" : "Пароль", text: $password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Повторите пароль", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
            }
            Text(passwordError ?? unlockGate.blurb)
                .font(.caption)
                .foregroundColor(passwordError == nil ? .secondary : .red)
        }
    }

    private func lockNow() {
        let store = SettingsStore.shared
        store.selectedMode = selectedMode
        store.soundEnabled = soundEnabled
        store.maxVolume = maxVolume
        store.sessionLimitMinutes = sessionLimitMinutes
        store.exitKeyCode = exitKeyCode
        store.exitModifiers = exitModifiers
        store.unlockGate = unlockGate

        if unlockGate == .password {
            if password.isEmpty && confirmPassword.isEmpty && KeychainManager.hasPassword {
                passwordError = nil
                onLockNow?()
                return
            }
            guard !password.isEmpty else { passwordError = "Введите пароль."; return }
            guard password == confirmPassword else { passwordError = "Пароли не совпадают."; return }
            KeychainManager.savePassword(password)
        }
        passwordError = nil
        onLockNow?()
    }
}

struct SettingsPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color.primary.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
    }
}

struct SettingRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 9) {
            Text(label).frame(width: 82, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }
}

private extension PlayModeType {
    var detail: String {
        switch self {
        case .letters: return "Все 33 буквы. Если включена русская раскладка, на экране появляется именно нажатая буква; иначе клавиши распределены по алфавиту. Голос работает офлайн."
        case .animals: return "Тридцать рисованных животных появляются по одному в случайном порядке. Голос спокойно произносит название, без очков, таймеров и конфетти."
        case .transport: return "Тридцать видов транспорта в том же книжном стиле и случайном порядке. Каждое нажатие меняет объект и называет его."
        case .musicStudio: return "Десять согласованных нот на семплированной челесте из системного банка macOS, с короткой комнатной реверберацией."
        }
    }
}

/// Sizes the settings window once SwiftUI has attached it to AppKit.
struct WindowConfigurator: NSViewRepresentable {
    let contentSize: NSSize
    let minSize: NSSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.contentMinSize = minSize
        if window.contentLayoutRect.size != contentSize { window.setContentSize(contentSize) }
    }
}
