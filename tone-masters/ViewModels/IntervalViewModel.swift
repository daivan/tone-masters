import SwiftUI
import Combine

// MARK: - Interval definitions

struct MusicalInterval: Identifiable {
    let id = UUID()
    let name: String        // "Perfect 5th"
    let shortName: String   // "P5"
    let semitones: Int      // 7
    let hint: String        // "Twinkle Twinkle (first two notes)"

    static let bank: [MusicalInterval] = [
        MusicalInterval(name: "Major 2nd",   shortName: "M2",  semitones: 2,  hint: "Happy Birthday"),
        MusicalInterval(name: "Minor 3rd",   shortName: "m3",  semitones: 3,  hint: "Smoke on the Water"),
        MusicalInterval(name: "Major 3rd",   shortName: "M3",  semitones: 4,  hint: "When the Saints Go Marching In"),
        MusicalInterval(name: "Perfect 4th", shortName: "P4",  semitones: 5,  hint: "Here Comes the Bride"),
        MusicalInterval(name: "Perfect 5th", shortName: "P5",  semitones: 7,  hint: "Twinkle Twinkle Little Star"),
        MusicalInterval(name: "Major 6th",   shortName: "M6",  semitones: 9,  hint: "My Bonnie Lies Over the Ocean"),
        MusicalInterval(name: "Octave",      shortName: "8ve", semitones: 12, hint: "Somewhere Over the Rainbow"),
    ]
}

// MARK: - Result types

struct IntervalRoundResult {
    let interval: MusicalInterval
    let rootMidi: Int
    let targetMidi: Int
    let meanAbsCents: Double
    var passed: Bool { meanAbsCents < 35 }
}

struct IntervalGameResult {
    let rounds: [IntervalRoundResult]
    var passedCount: Int { rounds.filter(\.passed).count }
    var scorePercent: Int { Int(Double(passedCount) / Double(max(1, rounds.count)) * 100) }
}

// MARK: - Phase

enum IntervalPhase: Equatable {
    case idle
    case playingRoot(round: Int)
    case playingInterval(round: Int)
    case countIn(round: Int, count: Int)
    case singing(round: Int)
    case revealing(round: Int, passed: Bool)
    case complete(IntervalGameResult)

    static func == (lhs: IntervalPhase, rhs: IntervalPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.playingRoot(let a), .playingRoot(let b)): return a == b
        case (.playingInterval(let a), .playingInterval(let b)): return a == b
        case (.countIn(let a, let x), .countIn(let b, let y)): return a == b && x == y
        case (.singing(let a), .singing(let b)): return a == b
        case (.revealing(let a, let x), .revealing(let b, let y)): return a == b && x == y
        case (.complete, .complete): return true
        default: return false
        }
    }
}

// MARK: - ViewModel

@MainActor
final class IntervalViewModel: ObservableObject {
    @Published var phase: IntervalPhase = .idle

    private(set) var rounds: [MusicalInterval] = []   // shuffled session intervals

    private let audioEngine: AudioEngine
    private let toneGenerator: ToneGenerator
    private let settings: VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var phaseTimer: Timer?
    private var sampleTimer: Timer?
    private var centsSamples: [Double] = []
    private var roundResults: [IntervalRoundResult] = []
    private var currentTargetMidi: Int = 60

    // Timings
    private let rootDuration:     TimeInterval = 1.5
    private let gapDuration:      TimeInterval = 0.3
    private let intervalDuration: TimeInterval = 1.5
    private let countInStep:      TimeInterval = 0.75
    private let singingDuration:  TimeInterval = 4.0

    init(audioEngine: AudioEngine, toneGenerator: ToneGenerator, settings: VoiceSettings) {
        self.audioEngine    = audioEngine
        self.toneGenerator  = toneGenerator
        self.settings       = settings
    }

    // MARK: - Public

    func start() {
        roundResults = []
        buildRounds()
        advanceToRound(0)
    }

    func proceedFromReveal() {
        guard case .revealing(let idx, _) = phase else { return }
        let next = idx + 1
        if next < rounds.count {
            advanceToRound(next)
        } else {
            phase = .complete(IntervalGameResult(rounds: roundResults))
        }
    }

    func skip() {
        guard case .singing(let idx) = phase else { return }
        endSinging(round: idx)
    }

    func restart() {
        cleanup()
        phase = .idle
        roundResults = []
    }

    func cleanup() {
        phaseTimer?.invalidate(); phaseTimer = nil
        sampleTimer?.invalidate(); sampleTimer = nil
        audioEngine.stopListening(owner: listenerID)
        toneGenerator.stop()
    }

    // MARK: - State machine

    private func advanceToRound(_ idx: Int) {
        let interval = rounds[idx]
        let rootMidi = settings.centerMidi
        let targetMidi = rootMidi + interval.semitones
        currentTargetMidi = targetMidi

        // Play root
        audioEngine.targetFrequency = midiToFreq(rootMidi)
        toneGenerator.play(frequency: midiToFreq(rootMidi))
        phase = .playingRoot(round: idx)

        schedule(after: rootDuration) { [weak self] in
            self?.toneGenerator.stop()
            // Brief gap then play interval
            self?.schedule(after: self?.gapDuration ?? 0.3) { [weak self] in
                guard let self else { return }
                self.toneGenerator.play(frequency: self.midiToFreq(targetMidi))
                self.phase = .playingInterval(round: idx)

                self.schedule(after: self.intervalDuration) { [weak self] in
                    self?.toneGenerator.stop()
                    self?.beginCountIn(round: idx, count: 3)
                }
            }
        }
    }

    private func beginCountIn(round: Int, count: Int) {
        phase = .countIn(round: round, count: count)
        let next = count - 1
        schedule(after: countInStep) { [weak self] in
            if next > 0 {
                self?.beginCountIn(round: round, count: next)
            } else {
                self?.beginSinging(round: round)
            }
        }
    }

    private func beginSinging(round: Int) {
        centsSamples = []
        audioEngine.targetFrequency = nil
        audioEngine.startListening(owner: listenerID)
        phase = .singing(round: round)

        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let freq = self.audioEngine.detectedFrequency else { return }
                let userMidi   = 69.0 + 12.0 * log2(freq / 440.0)
                let targetMidi = Double(self.currentTargetMidi)
                self.centsSamples.append(abs((userMidi - targetMidi) * 100.0))
            }
        }

        schedule(after: singingDuration) { [weak self] in
            self?.endSinging(round: round)
        }
    }

    private func endSinging(round: Int) {
        sampleTimer?.invalidate(); sampleTimer = nil
        phaseTimer?.invalidate();  phaseTimer  = nil
        audioEngine.stopListening(owner: listenerID)

        let mean = centsSamples.isEmpty ? 100.0
                   : centsSamples.reduce(0, +) / Double(centsSamples.count)
        let interval   = rounds[round]
        let rootMidi   = settings.centerMidi
        let targetMidi = rootMidi + interval.semitones
        let result     = IntervalRoundResult(interval: interval, rootMidi: rootMidi,
                                             targetMidi: targetMidi, meanAbsCents: mean)
        roundResults.append(result)
        phase = .revealing(round: round, passed: result.passed)
    }

    // MARK: - Helpers

    private func buildRounds() {
        // Pick 5 intervals, randomly shuffled, all fitting within the user's range
        let maxSemitones = 12   // user range is ±12 from center
        let eligible = MusicalInterval.bank.filter { $0.semitones <= maxSemitones }
        rounds = Array(eligible.shuffled().prefix(5))
    }

    private func midiToFreq(_ midi: Int) -> Double {
        440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
    }

    private func schedule(after delay: TimeInterval, block: @escaping () -> Void) {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in block() }
        }
    }

    // MARK: - UI helpers

    var currentRound: Int? {
        switch phase {
        case .playingRoot(let r), .playingInterval(let r),
             .countIn(let r, _), .singing(let r), .revealing(let r, _): return r
        default: return nil
        }
    }

    var currentInterval: MusicalInterval? {
        guard let r = currentRound, r < rounds.count else { return nil }
        return rounds[r]
    }

    var rootNoteName: String { midiNoteName(settings.centerMidi) }

    var targetNoteName: String? {
        guard let interval = currentInterval else { return nil }
        return midiNoteName(settings.centerMidi + interval.semitones)
    }

    var phaseLabel: String {
        switch phase {
        case .idle:                          return "Tap Start"
        case .playingRoot:                   return "Listen — root note…"
        case .playingInterval(let r):
            let name = r < rounds.count ? rounds[r].name : ""
            return "Listen — \(name)↑"
        case .countIn(_, let n):             return "\(n)"
        case .singing:                       return "Sing the interval!"
        case .revealing(_, let passed):      return passed ? "In tune!" : "Keep training!"
        case .complete:                      return "Session complete!"
        }
    }

    var resultForCurrentRound: IntervalRoundResult? {
        guard case .revealing(let r, _) = phase else { return nil }
        return roundResults.indices.contains(r) ? roundResults[r] : nil
    }
}
