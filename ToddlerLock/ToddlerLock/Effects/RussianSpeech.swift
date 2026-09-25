import AVFoundation

/// Calm, offline Russian narration. Requests are slightly delayed so a
/// toddler mashing several keys hears the final item instead of chopped-up
/// syllables from every intermediate press.
final class RussianSpeech {
    static let shared = RussianSpeech()

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
            utterance.voice = Self.russianVoice
            utterance.rate = 0.40
            utterance.pitchMultiplier = 1.0
            utterance.volume = Float(SettingsStore.shared.maxVolume)
            utterance.preUtteranceDelay = 0.04
            utterance.postUtteranceDelay = 0.08
            self.synthesizer.speak(utterance)
        }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: item)
    }

    func stop() {
        pending?.cancel()
        pending = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private static var russianVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices().first {
            $0.language.replacingOccurrences(of: "_", with: "-") == "ru-RU" && $0.name == "Milena"
        } ?? AVSpeechSynthesisVoice(language: "ru-RU")
    }
}
