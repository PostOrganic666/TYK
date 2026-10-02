import Foundation

@main
struct AlphabetProgressTests {
    static func main() {
        var gate = PlayInteractionGate()
        var progress = AlphabetProgress()
        precondition(progress.letter.glyph == "А" && progress.visiblePictureCount == 0)
        // Automatic initial letter narration starts a two-second minimum interval.
        precondition(gate.accept(at: 100, minimumInterval: 2, speechBusy: false))
        func tap(_ time: TimeInterval, busy: Bool) {
            if gate.accept(at: time, minimumInterval: 2, speechBusy: busy) { progress.advance() }
        }
        tap(100.1, busy: true) // the scheduled start is busy too
        tap(101, busy: false)
        precondition(progress.stage == 0)
        tap(102, busy: false)
        precondition(progress.visiblePictureCount == 1)
        tap(102.1, busy: true)
        tap(110, busy: true) // a long clip cannot be interrupted after the pause
        precondition(progress.visiblePictureCount == 1)
        tap(110.1, busy: false)
        precondition(progress.visiblePictureCount == 2)
        tap(112.1, busy: false)
        precondition(progress.visiblePictureCount == 3 && progress.letter.glyph == "А")
        tap(114.1, busy: false)
        precondition(progress.visiblePictureCount == 0 && progress.letter.glyph == "Б")
        // Every letter has exactly four stages, and Я wraps to А without old pictures.
        for index in 1..<33 {
            precondition(progress.letterIndex == index && progress.stage == 0)
            for count in 1...3 {
                progress.advance()
                precondition(progress.visiblePictureCount == count && progress.letterIndex == index)
            }
            progress.advance()
        }
        precondition(progress.letter.glyph == "А" && progress.stage == 0)
        // Switching the pause off still waits for speech, and never builds a click queue.
        var noPause = PlayInteractionGate()
        precondition(!noPause.accept(at: 1, minimumInterval: 0, speechBusy: true))
        precondition(noPause.accept(at: 1, minimumInterval: 0, speechBusy: false))
        precondition(!noPause.accept(at: 2, minimumInterval: 0, speechBusy: true))
        precondition(noPause.accept(at: 2, minimumInterval: 0, speechBusy: false))
        print("OK: 33 letters, reveal order, wraparound, mixed rapid input, long speech and zero pause")
    }
}
