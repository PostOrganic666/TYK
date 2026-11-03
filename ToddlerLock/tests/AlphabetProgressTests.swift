import Foundation

@main
struct AlphabetProgressTests {
    static func main() {
        var gate = PlayInteractionGate()
        var progress = AlphabetProgress()
        let firstLetter = progress.letterIndex
        precondition(progress.visiblePictureCount == 0)
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
        precondition(progress.visiblePictureCount == 3 && progress.letterIndex == firstLetter)
        tap(114.1, busy: false)
        precondition(progress.visiblePictureCount == 0 && progress.letterIndex != firstLetter)
        testShuffleCycles()
        // Switching the pause off still waits for speech, and never builds a click queue.
        var noPause = PlayInteractionGate()
        precondition(!noPause.accept(at: 1, minimumInterval: 0, speechBusy: true))
        precondition(noPause.accept(at: 1, minimumInterval: 0, speechBusy: false))
        precondition(!noPause.accept(at: 2, minimumInterval: 0, speechBusy: true))
        precondition(noPause.accept(at: 2, minimumInterval: 0, speechBusy: false))
        print("OK: shuffled letters, six examples, cycle boundaries, reveal stages and speech pacing")
    }

    static func testShuffleCycles() {
        var startingLetters = Set<Int>()
        var orders = Set<[Int]>()
        for seed in 1...40 {
            var generator = SeededGenerator(state: UInt64(seed))
            var progress = AlphabetProgress(using: &generator)
            startingLetters.insert(progress.letterIndex)
            var recentLetters: [Int] = []
            var pictureHistory = Array(repeating: [Int](), count: 33)
            var firstCycle: [Int] = []
            // Multiple boundaries, including partial-cycle endings on each letter.
            for _ in 0..<20 {
                var cycle = Set<Int>()
                for _ in 0..<33 {
                    let letter = progress.letterIndex
                    precondition(!recentLetters.suffix(8).contains(letter))
                    precondition(cycle.insert(letter).inserted)
                    recentLetters.append(letter)
                    if firstCycle.count < 33 { firstCycle.append(letter) }
                    let selection = progress.pictureIndices
                    precondition(selection.count == 3 && Set(selection).count == 3)
                    precondition(selection.allSatisfy { (0..<6).contains($0) })
                    for picture in selection {
                        precondition(!pictureHistory[letter].suffix(3).contains(picture))
                        pictureHistory[letter].append(picture)
                        if pictureHistory[letter].count.isMultiple(of: 6) {
                            precondition(Set(pictureHistory[letter].suffix(6)).count == 6)
                        }
                    }
                    precondition(progress.stage == 0 && progress.visiblePictureCount == 0)
                    for count in 1...3 {
                        progress.advance(using: &generator)
                        precondition(progress.stage == count && progress.visiblePictureCount == count)
                        precondition(progress.letterIndex == letter && progress.pictureIndices == selection)
                    }
                    progress.advance(using: &generator)
                }
                precondition(cycle.count == 33)
            }
            orders.insert(firstCycle)
        }
        precondition(startingLetters.count > 1 && orders.count > 1)
        // Fixed seeds make regression failures reproducible.
        var a = SeededGenerator(state: 123)
        var b = SeededGenerator(state: 123)
        var left = AlphabetProgress(using: &a)
        var right = AlphabetProgress(using: &b)
        for _ in 0..<400 {
            precondition(left.letterIndex == right.letterIndex && left.pictureIndices == right.pictureIndices)
            left.advance(using: &a)
            right.advance(using: &b)
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
