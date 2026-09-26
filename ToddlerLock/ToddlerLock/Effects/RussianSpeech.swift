import AVFoundation

struct RussianVoiceChoice: Identifiable {
    let id: String
    let title: String
}

/// Offline Russian narration. Requests are slightly delayed so a
/// toddler mashing several keys hears the final item instead of chopped-up
/// syllables from every intermediate press.
final class RussianSpeech {
    static let shared = RussianSpeech()
    static let preferredVoiceIdentifier = "yelena-premium"
    static let voiceChoices = [
        RussianVoiceChoice(id: preferredVoiceIdentifier, title: "Елена — живая"),
        RussianVoiceChoice(id: "milena", title: "Милена — спокойная"),
    ]

    private static let yelenaSystemIdentifier =
        "com.apple.speech.synthesis.voice.custom.siri.yelena.premium"

    private let synthesizer = AVSpeechSynthesizer()
    private var pending: DispatchWorkItem?

    private init() {}

    func speak(_ text: String) {
        guard SettingsStore.shared.soundEnabled else { return }
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.synthesizer.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: text)
            let choice = SettingsStore.shared.speechVoiceIdentifier
            utterance.voice = Self.voice(for: choice)
            utterance.rate = choice == Self.preferredVoiceIdentifier ? 0.46 : 0.43
            utterance.pitchMultiplier = choice == Self.preferredVoiceIdentifier ? 1.03 : 1.08
            utterance.volume = Float(SettingsStore.shared.maxVolume)
            utterance.preUtteranceDelay = 0.04
            utterance.postUtteranceDelay = 0.08
            self.synthesizer.speak(utterance)
        }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: item)
    }

    func preview(voiceIdentifier: String, volume: Double) {
        pending?.cancel()
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: "Привет! Давай играть!")
        utterance.voice = Self.voice(for: voiceIdentifier)
        utterance.rate = voiceIdentifier == Self.preferredVoiceIdentifier ? 0.46 : 0.43
        utterance.pitchMultiplier = voiceIdentifier == Self.preferredVoiceIdentifier ? 1.03 : 1.08
        utterance.volume = Float(volume)
        synthesizer.speak(utterance)
    }

    func stop() {
        pending?.cancel()
        pending = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static func voice(for choice: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if choice == preferredVoiceIdentifier {
            return AVSpeechSynthesisVoice(identifier: yelenaSystemIdentifier)
                ?? voices.first {
                    let name = $0.name.lowercased()
                    return isRussian($0) && (name.contains("yelena") || name.contains("елена"))
                }
                ?? milena(in: voices)
        }
        return milena(in: voices)
    }

    private static func milena(in voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        voices.first { isRussian($0) && $0.name.lowercased().contains("milena") }
            ?? AVSpeechSynthesisVoice(language: "ru-RU")
    }

    private static func isRussian(_ voice: AVSpeechSynthesisVoice) -> Bool {
        voice.language.replacingOccurrences(of: "_", with: "-") == "ru-RU"
    }
}
