import Foundation

/// Stage 0 speaks the letter; stages 1...3 reveal exactly one new example.
/// A new session starts at А, voiced automatically on opening.
struct AlphabetProgress {
    private(set) var letterIndex = 0
    private(set) var stage = 0

    mutating func advance() {
        if stage == 3 {
            letterIndex = (letterIndex + 1) % RussianAlphabet.letters.count
            stage = 0
        } else {
            stage += 1
        }
    }

    var visiblePictureCount: Int { max(0, stage) }
    var letter: RussianLetter { RussianAlphabet.letters[letterIndex] }
}

/// A minimum interval measured from the last accepted tap, using monotonic time.
/// Speech always runs to completion, even if the minimum interval is zero.
struct PlayInteractionGate {
    private var lastAcceptedTime: TimeInterval?

    mutating func accept(at time: TimeInterval, minimumInterval: TimeInterval, speechBusy: Bool) -> Bool {
        guard !speechBusy else { return false }
        if let lastAcceptedTime, time - lastAcceptedTime < minimumInterval { return false }
        lastAcceptedTime = time
        return true
    }
}
