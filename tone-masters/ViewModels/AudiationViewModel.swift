import SwiftUI
import Combine

// MARK: - Result types

struct AudiationNoteResult {
    let midiNote: Int
    let meanAbsCents: Double
    var passed: Bool { meanAbsCents < 30 }
}

struct AudiationResult {
    let noteResults: [AudiationNoteResult]
    var passedCount: Int { noteResults.filter(\.passed).count }
    var scorePercent: Int { Int(Double(passedCount) / Double(max(1, noteResults.count)) * 100) }
}

// MARK: - Phase

enum AudiationPhase: Equatable {
    case idle
    case playingTone(noteIndex: Int)
    case countIn(noteIndex: Int, count: Int)   // 3 → 2 → 1
    case singing(noteIndex: Int)
    case revealing(noteIndex: Int, passed: Bool)
    case complete(AudiationResult)

    static func == (lhs: AudiationPhase, rhs: AudiationPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.playingTone(let a), .playingTone(let b)): return a == b
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
final class AudiationViewModel: ObservableObject {
    @Published var phase: AudiationPhase = .idle
    @Published var currentDetectedNote: String? = nil

    // 5 notes per session: root + maj2 + maj3 + perf5 + octave
    private(set) var notes: [Int] = []

    private let audioEngine: AudioEngine
    private let toneGenerator: ToneGenerator
    private let settings: VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var phaseTimer: Timer?
    private var sampleTimer: Timer?
    private var centsSamples: [Double] = []
    private var noteResults: [AudiationNoteResult] = []

    // Timings
    private let toneDuration:    TimeInterval = 2.0
    private let countInStep:     TimeInterval = 0.75
    private let singingDuration: TimeInterval = 4.0

    init(audioEngine: AudioEngine, toneGenerator: ToneGenerator, settings: VoiceSettings) {
        self.audioEngine    = audioEngine
        self.toneGenerator  = toneGenerator
        self.settings       = settings
        buildNoteSet()
        observeAudioEngine()
    }

    // MARK: - Public

    func start() {
        noteResults = []
        buildNoteSet()
        advanceToNote(0)
    }

    /// Called when the user taps "Next" during the revealing phase.
    func proceedFromReveal() {
        guard case .revealing(let idx, _) = phase else { return }
        let next = idx + 1
        if next < notes.count {
            advanceToNote(next)
        } else {
            phase = .complete(AudiationResult(noteResults: noteResults))
        }
    }

    /// Called when the user taps "Skip" during the singing phase.
    func skip() {
        guard case .singing(let idx) = phase else { return }
        endSinging(noteIndex: idx)
    }

    func restart() {
        cleanup()
        phase = .idle
        noteResults = []
    }

    func cleanup() {
        phaseTimer?.invalidate(); phaseTimer = nil
        sampleTimer?.invalidate(); sampleTimer = nil
        audioEngine.stopListening(owner: listenerID)
        toneGenerator.stop()
    }

    // MARK: - State machine

    private func advanceToNote(_ index: Int) {
        let freq = midiToFrequency(notes[index])
        audioEngine.targetFrequency = freq
        toneGenerator.play(frequency: freq)
        phase = .playingTone(noteIndex: index)

        schedule(after: toneDuration) { [weak self] in
            self?.toneGenerator.stop()
            self?.beginCountIn(noteIndex: index, count: 3)
        }
    }

    private func beginCountIn(noteIndex: Int, count: Int) {
        phase = .countIn(noteIndex: noteIndex, count: count)
        let nextCount = count - 1
        schedule(after: countInStep) { [weak self] in
            if nextCount > 0 {
                self?.beginCountIn(noteIndex: noteIndex, count: nextCount)
            } else {
                self?.beginSinging(noteIndex: noteIndex)
            }
        }
    }

    private func beginSinging(noteIndex: Int) {
        centsSamples = []
        audioEngine.targetFrequency = nil   // no reference; pure audiation
        audioEngine.startListening(owner: listenerID)
        phase = .singing(noteIndex: noteIndex)

        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.audioEngine.detectedFrequency != nil {
                    self.centsSamples.append(abs(self.audioEngine.centsDeviation))
                }
            }
        }

        schedule(after: singingDuration) { [weak self] in
            self?.endSinging(noteIndex: noteIndex)
        }
    }

    private func endSinging(noteIndex: Int) {
        sampleTimer?.invalidate(); sampleTimer = nil
        phaseTimer?.invalidate(); phaseTimer = nil
        audioEngine.stopListening(owner: listenerID)

        let mean = centsSamples.isEmpty ? 100.0
                   : centsSamples.reduce(0, +) / Double(centsSamples.count)
        let result = AudiationNoteResult(midiNote: notes[noteIndex], meanAbsCents: mean)
        noteResults.append(result)

        phase = .revealing(noteIndex: noteIndex, passed: result.passed)
    }

    // MARK: - Helpers

    private func buildNoteSet() {
        let center = settings.centerMidi
        // Major scale root + 2 + 4 + 7 + 12 (octave): musical and achievable
        notes = [center, center + 2, center + 4, center + 7, center + 9]
    }

    private func midiToFrequency(_ midi: Int) -> Double {
        440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
    }

    private func schedule(after delay: TimeInterval, block: @escaping () -> Void) {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in block() }
        }
    }

    private func observeAudioEngine() {
        audioEngine.$detectedNote
            .receive(on: RunLoop.main)
            .assign(to: \.currentDetectedNote, on: self)
            .store(in: &cancellables)
    }

    // MARK: - UI helpers

    var currentNoteIndex: Int? {
        switch phase {
        case .playingTone(let i), .countIn(let i, _), .singing(let i), .revealing(let i, _): return i
        default: return nil
        }
    }

    var currentNoteName: String? {
        guard let i = currentNoteIndex, i < notes.count else { return nil }
        return midiNoteName(notes[i])
    }

    var phaseLabel: String {
        switch phase {
        case .idle:                           return "Tap Start to begin"
        case .playingTone:                    return "Listen carefully…"
        case .countIn(_, let n):              return "\(n)"
        case .singing:                        return "Sing!"
        case .revealing(_, let passed):       return passed ? "Well done!" : "Keep going!"
        case .complete:                       return "Session complete!"
        }
    }

    var resultForCurrentNote: AudiationNoteResult? {
        guard case .revealing(let i, _) = phase else { return nil }
        return noteResults.indices.contains(i) ? noteResults[i] : nil
    }
}
