import Foundation

/// A shuffled cycle visits every item once, with a gap across cycle boundaries.
struct AlphabetShuffleBag {
    private let count: Int
    private let minimumGap: Int
    private var remaining: [Int] = []
    private var recent: [Int] = []

    init(count: Int, minimumGap: Int) {
        precondition(count > 0)
        self.count = count
        self.minimumGap = min(max(0, minimumGap), count / 2)
    }

    mutating func next<Generator: RandomNumberGenerator>(using generator: inout Generator) -> Int {
        if remaining.isEmpty { remaining = Array(0..<count).shuffled(using: &generator) }
        // At most half a cycle is excluded, so an eligible item always exists.
        let index = remaining.firstIndex { !recent.contains($0) }!
        let value = remaining.remove(at: index)
        recent.append(value)
        if recent.count > minimumGap { recent.removeFirst() }
        return value
    }
}

/// Stage 0 speaks a random letter; stages 1...3 reveal its selected examples.
struct AlphabetProgress {
    private(set) var letterIndex: Int
    private(set) var stage = 0
    private(set) var pictureIndices: [Int] = []
    private var letters = AlphabetShuffleBag(count: RussianAlphabet.letters.count, minimumGap: 8)
    private var pictures: [AlphabetShuffleBag]

    init(exampleCounts: [Int] = Array(repeating: 6, count: RussianAlphabet.letters.count)) {
        var generator = SystemRandomNumberGenerator()
        self.init(exampleCounts: exampleCounts, using: &generator)
    }

    init<Generator: RandomNumberGenerator>(
        exampleCounts: [Int] = Array(repeating: 6, count: RussianAlphabet.letters.count),
        using generator: inout Generator
    ) {
        precondition(exampleCounts.count == RussianAlphabet.letters.count)
        precondition(exampleCounts.allSatisfy { $0 >= 3 && $0.isMultiple(of: 3) })
        pictures = exampleCounts.map { AlphabetShuffleBag(count: $0, minimumGap: 3) }
        letterIndex = 0
        chooseLetter(using: &generator)
    }

    mutating func advance() {
        var generator = SystemRandomNumberGenerator()
        advance(using: &generator)
    }

    mutating func advance<Generator: RandomNumberGenerator>(using generator: inout Generator) {
        if stage == 3 {
            chooseLetter(using: &generator)
            stage = 0
        } else {
            stage += 1
        }
    }

    var visiblePictureCount: Int { max(0, stage) }
    var letter: RussianLetter { RussianAlphabet.letters[letterIndex] }

    private mutating func chooseLetter<Generator: RandomNumberGenerator>(using generator: inout Generator) {
        letterIndex = letters.next(using: &generator)
        pictureIndices = (0..<3).map { _ in pictures[letterIndex].next(using: &generator) }
    }
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
