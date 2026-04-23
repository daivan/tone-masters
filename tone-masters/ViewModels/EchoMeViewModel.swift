import SwiftUI
import Combine

// MARK: - Data model

struct EchoPhrase: Identifiable {
    let id = UUID()
    let name: String
    let notes: [(semitones: Int, beats: Double)]
    let bpm: Double

    var totalBeats: Double { notes.reduce(0) { $0 + $1.beats } }
    var totalDuration: TimeInterval { totalBeats * 60.0 / bpm }

    func noteStartTime(_ index: Int) -> TimeInterval {
        notes.prefix(index).reduce(0.0) { $0 + $1.beats } * 60.0 / bpm
    }
    func noteDuration(_ index: Int) -> TimeInterval {
        notes[index].beats * 60.0 / bpm
    }

    static let bank: [EchoPhrase] = [
        EchoPhrase(name: "Step Up",     notes: [(0,1),(2,1),(4,1),(5,1)],               bpm: 72),
        EchoPhrase(name: "Jump & Fall", notes: [(0,1),(7,1),(5,1),(4,1)],               bpm: 72),
        EchoPhrase(name: "Arpeggio",    notes: [(0,1),(4,1),(7,1),(4,1),(0,2)],         bpm: 80),
        EchoPhrase(name: "Scale Run",   notes: [(0,0.5),(2,0.5),(4,0.5),(5,0.5),(7,1)], bpm: 88),
        EchoPhrase(name: "Mirror",      notes: [(4,1),(2,1),(0,1),(2,1),(4,2)],         bpm: 72),
    ]
}

// MARK: - Result types

struct EchoNoteResult {
    let semitones: Int
    let hitFrames: Int
    let totalFrames: Int
    var hitRate: Double { totalFrames > 0 ? Double(hitFrames) / Double(totalFrames) : 0 }
    var passed: Bool { hitRate >= 0.5 }
}

struct EchoPhraseResult {
    let phrase: EchoPhrase
    let noteResults: [EchoNoteResult]
    var passedCount: Int { noteResults.filter(\.passed).count }
    var scorePercent: Int { Int(Double(passedCount) / Double(max(1, noteResults.count)) * 100) }
}

struct EchoGameResult {
    let phraseResults: [EchoPhraseResult]
    var overallPercent: Int {
        phraseResults.isEmpty ? 0 :
        phraseResults.reduce(0) { $0 + $1.scorePercent } / phraseResults.count
    }
}

// MARK: - Phase

enum EchoPhase: Equatable {
    case idle
    case playingPhrase(phraseIndex: Int, noteIndex: Int)
    case countIn(phraseIndex: Int, count: Int)
    case singing(phraseIndex: Int)
    case revealing(phraseIndex: Int)
    case complete
}

// MARK: - ViewModel

@MainActor
final class EchoMeViewModel: ObservableObject {
    @Published var phase: EchoPhase = .idle

    private(set) var phrases: [EchoPhrase] = []
    private(set) var phraseResults: [EchoPhraseResult] = []
    private(set) var gameResult: EchoGameResult?

    private var hitFrames:   [Int] = []
    private var totalFrames: [Int] = []
    private var singingStart: Date = .now

    private let audioEngine:   AudioEngine
    private let toneGenerator: ToneGenerator
    private let settings:      VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var phaseTimer: Timer?
    private var sampleTimer: Timer?

    private let notePause:     TimeInterval = 0.08
    private let countInStep:   TimeInterval = 0.75
    private let thresholdCents: Double      = 50.0

    init(audioEngine: AudioEngine, toneGenerator: ToneGenerator, settings: VoiceSettings) {
        self.audioEngine   = audioEngine
        self.toneGenerator = toneGenerator
        self.settings      = settings
    }

    // MARK: - Public

    func start() {
        phraseResults = []
        gameResult    = nil
        phrases       = Array(EchoPhrase.bank.shuffled().prefix(3))
        advanceToPhrase(0)
    }

    func proceedFromReveal() {
        guard case .revealing(let idx) = phase else { return }
        let next = idx + 1
        if next < phrases.count {
            advanceToPhrase(next)
        } else {
            gameResult = EchoGameResult(phraseResults: phraseResults)
            phase = .complete
        }
    }

    func skip() {
        guard case .singing(let idx) = phase else { return }
        endSinging(phraseIndex: idx)
    }

    func restart() {
        cleanup()
        phase = .idle
        phraseResults = []
        gameResult = nil
    }

    func cleanup() {
        phaseTimer?.invalidate(); phaseTimer = nil
        sampleTimer?.invalidate(); sampleTimer = nil
        audioEngine.stopListening(owner: listenerID)
        toneGenerator.stop()
    }

    // MARK: - State machine

    private func advanceToPhrase(_ idx: Int) {
        schedule(after: 0.3) { [weak self] in
            self?.playNote(phraseIndex: idx, noteIndex: 0)
        }
    }

    private func playNote(phraseIndex: Int, noteIndex: Int) {
        let phrase     = phrases[phraseIndex]
        let note       = phrase.notes[noteIndex]
        let targetMidi = settings.centerMidi + note.semitones

        toneGenerator.play(frequency: midiToFreq(targetMidi))
        phase = .playingPhrase(phraseIndex: phraseIndex, noteIndex: noteIndex)

        schedule(after: phrase.noteDuration(noteIndex)) { [weak self] in
            guard let self else { return }
            self.toneGenerator.stop()
            let next = noteIndex + 1
            if next < phrase.notes.count {
                self.schedule(after: self.notePause) { [weak self] in
                    self?.playNote(phraseIndex: phraseIndex, noteIndex: next)
                }
            } else {
                self.schedule(after: 0.4) { [weak self] in
                    self?.beginCountIn(phraseIndex: phraseIndex, count: 3)
                }
            }
        }
    }

    private func beginCountIn(phraseIndex: Int, count: Int) {
        phase = .countIn(phraseIndex: phraseIndex, count: count)
        let next = count - 1
        schedule(after: countInStep) { [weak self] in
            if next > 0 {
                self?.beginCountIn(phraseIndex: phraseIndex, count: next)
            } else {
                self?.beginSinging(phraseIndex: phraseIndex)
            }
        }
    }

    private func beginSinging(phraseIndex: Int) {
        let phrase  = phrases[phraseIndex]
        hitFrames   = Array(repeating: 0, count: phrase.notes.count)
        totalFrames = Array(repeating: 0, count: phrase.notes.count)
        singingStart = .now

        audioEngine.startListening(owner: listenerID)
        phase = .singing(phraseIndex: phraseIndex)

        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let freq = self.audioEngine.detectedFrequency else { return }
                let elapsed = Date.now.timeIntervalSince(self.singingStart)
                let p = self.phrases[phraseIndex]
                for i in p.notes.indices {
                    let start = p.noteStartTime(i)
                    let end   = start + p.noteDuration(i)
                    guard elapsed >= start && elapsed < end else { continue }
                    let targetMidi = Double(self.settings.centerMidi + p.notes[i].semitones)
                    let userMidi   = 69.0 + 12.0 * log2(freq / 440.0)
                    let centsOff   = abs((userMidi - targetMidi) * 100.0)
                    self.totalFrames[i] += 1
                    if centsOff <= self.thresholdCents { self.hitFrames[i] += 1 }
                    break
                }
            }
        }

        schedule(after: phrase.totalDuration + 0.3) { [weak self] in
            self?.endSinging(phraseIndex: phraseIndex)
        }
    }

    private func endSinging(phraseIndex: Int) {
        sampleTimer?.invalidate(); sampleTimer = nil
        phaseTimer?.invalidate();  phaseTimer  = nil
        audioEngine.stopListening(owner: listenerID)

        let phrase = phrases[phraseIndex]
        let results = phrase.notes.indices.map { i in
            EchoNoteResult(semitones: phrase.notes[i].semitones,
                           hitFrames: hitFrames[i],
                           totalFrames: totalFrames[i])
        }
        phraseResults.append(EchoPhraseResult(phrase: phrase, noteResults: results))
        phase = .revealing(phraseIndex: phraseIndex)
    }

    // MARK: - Helpers

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

    var currentPhraseIndex: Int? {
        switch phase {
        case .playingPhrase(let i, _), .countIn(let i, _),
             .singing(let i), .revealing(let i): return i
        default: return nil
        }
    }

    var currentPhrase: EchoPhrase? {
        guard let i = currentPhraseIndex, i < phrases.count else { return nil }
        return phrases[i]
    }

    var activeNoteIndex: Int? {
        if case .playingPhrase(_, let n) = phase { return n }
        return nil
    }

    var resultForCurrentPhrase: EchoPhraseResult? {
        guard case .revealing(let i) = phase else { return nil }
        return phraseResults.indices.contains(i) ? phraseResults[i] : nil
    }

    var phaseLabel: String {
        switch phase {
        case .idle:          return "Get ready"
        case .playingPhrase: return "Listen carefully…"
        case .countIn:       return ""
        case .singing:       return "Echo it back!"
        case .revealing:     return ""
        case .complete:      return "Session complete!"
        }
    }
}
