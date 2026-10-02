import AVFoundation

struct RussianVoiceChoice: Identifiable {
    let id: String
    let title: String
}

/// Bundled Russian Kore recordings. The shared input gate lets each clip finish;
/// an unknown/new label uses the offline system voice.
final class RussianSpeech {
    static let shared = RussianSpeech()
    static let preferredVoiceIdentifier = "gemini-kore"
    static let voiceChoices = [
        RussianVoiceChoice(id: preferredVoiceIdentifier, title: "Kore — женский"),
    ]

    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var pending: DispatchWorkItem?
    private let recordingNames: [String: String] = {
        guard let url = Bundle.main.url(forResource: "speech-index", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let index = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return index
    }()

    private init() {}

    /// Includes the short scheduled start, so a second press cannot cancel it.
    var isBusy: Bool {
        pending != nil || player?.isPlaying == true || synthesizer.isSpeaking || synthesizer.isPaused
    }

    func speak(_ text: String) {
        guard SettingsStore.shared.soundEnabled else { return }
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pending = nil
            self.play(text, volume: SettingsStore.shared.maxVolume)
        }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: item)
    }

    func preview(voiceIdentifier: String, volume: Double) {
        stop()
        play("Привет! Давай играть!", volume: volume)
    }

    func stop() {
        pending?.cancel()
        pending = nil
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func play(_ text: String, volume: Double) {
        player?.stop()
        player = nil
        synthesizer.stopSpeaking(at: .immediate)
        if let name = recordingNames[text],
           let url = Bundle.main.url(forResource: name, withExtension: "wav"),
           let recording = try? AVAudioPlayer(contentsOf: url) {
            recording.volume = Float(volume)
            player = recording
            if recording.play() { return }
            player = nil
        }
        // New content remains audible until its Kore recording is generated.
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.43
        utterance.volume = Float(volume)
        synthesizer.speak(utterance)
    }
}
