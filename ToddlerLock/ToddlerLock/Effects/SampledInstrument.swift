import AVFoundation
import AudioToolbox

/// A real sampled celesta from macOS' bundled General MIDI sound bank.
/// Unlike the upstream oscillator, every note contains an acoustic attack,
/// overtones and decay. A small room reverb keeps rapid random notes musical.
final class SampledInstrument {
    static let shared = SampledInstrument()

    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let reverb = AVAudioUnitReverb()
    private var isReady = false

    var volume: Float = 0.75 {
        didSet { engine.mainMixerNode.outputVolume = min(1, max(0, volume)) }
    }

    private init() {
        engine.attach(sampler)
        engine.attach(reverb)
        reverb.loadFactoryPreset(.mediumRoom)
        reverb.wetDryMix = 22
        engine.connect(sampler, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)

        let bank = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")
        do {
            // General MIDI program 8 is celesta (program numbers are zero-based).
            try sampler.loadSoundBankInstrument(
                at: bank,
                program: 8,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            try engine.start()
            isReady = true
            engine.mainMixerNode.outputVolume = volume
        } catch {
            // Silence is preferable to falling back to a harsh oscillator.
            NSLog("Sampled instrument unavailable: %@", String(describing: error))
        }
    }

    func play(scaleIndex: Int, velocity: UInt8 = 82) {
        guard isReady else { return }
        // C-major pentatonic over two octaves; arbitrary key mashing remains consonant.
        let notes: [UInt8] = [60, 62, 64, 67, 69, 72, 74, 76, 79, 81]
        let note = notes[abs(scaleIndex) % notes.count]
        sampler.startNote(note, withVelocity: velocity, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) { [weak self] in
            self?.sampler.stopNote(note, onChannel: 0)
        }
    }

    func stop() {
        guard isReady else { return }
        for note in UInt8(0)...UInt8(127) {
            sampler.stopNote(note, onChannel: 0)
        }
    }
}

