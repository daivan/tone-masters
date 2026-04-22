import SwiftUI
import Combine

enum ExercisePhase: Equatable {
    case idle
    case playingReference(noteIndex: Int)
    case countIn(noteIndex: Int)
    case listening(noteIndex: Int)
    case gradingResult(noteIndex: Int, passed: Bool)
    case complete(ExerciseResult)
}

@MainActor
final class ExerciseViewModel: ObservableObject {
    @Published var phase: ExercisePhase = .idle
    @Published var selectedScale: ScaleDefinition = ScaleLibrary.cMajor
    @Published var currentCentsDeviation: Double = 0
    @Published var currentDetectedNote: String? = nil
    @Published var currentDetectedFrequency: Double? = nil

    private let audioEngine: AudioEngine
    private let toneGenerator: ToneGenerator
    private let listenerID = UUID()

    private var phaseTimer: Timer?
    private var sampleTimer: Timer?
    private var centsSamples: [Double] = []
    private var noteResults: [NoteResult] = []
    private var cancellables = Set<AnyCancellable>()

    // Phase timings (seconds)
    private let referencePlayDuration: TimeInterval = 1.5
    private let countInDuration: TimeInterval = 0.5
    private let listeningDuration: TimeInterval = 2.0
    private let gradingFlashDuration: TimeInterval = 0.8

    init(audioEngine: AudioEngine, toneGenerator: ToneGenerator) {
        self.audioEngine = audioEngine
        self.toneGenerator = toneGenerator
        observeAudioEngine()
    }

    // MARK: - Observation

    private func observeAudioEngine() {
        audioEngine.$centsDeviation
            .receive(on: RunLoop.main)
            .sink { [weak self] cents in
                self?.currentCentsDeviation = cents
            }
            .store(in: &cancellables)

        audioEngine.$detectedNote
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                self?.currentDetectedNote = note
            }
            .store(in: &cancellables)

        audioEngine.$detectedFrequency
            .receive(on: RunLoop.main)
            .sink { [weak self] freq in
                self?.currentDetectedFrequency = freq
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Actions

    func startExercise() {
        noteResults = []
        advanceToNote(0)
    }

    func skipNote() {
        guard case .listening(let idx) = phase else { return }
        endListeningPhase(noteIndex: idx)
    }

    func restartExercise() {
        cleanup()
        phase = .idle
        noteResults = []
    }

    func cleanup() {
        cancelTimers()
        audioEngine.stopListening(owner: listenerID)
        toneGenerator.stop()
    }

    // MARK: - State Machine

    private func advanceToNote(_ index: Int) {
        let note = selectedScale.notes[index]
        audioEngine.targetFrequency = note.frequency

        toneGenerator.play(frequency: note.frequency)
        phase = .playingReference(noteIndex: index)

        schedule(after: referencePlayDuration) { [weak self] in
            self?.toneGenerator.stop()
            self?.phase = .countIn(noteIndex: index)

            self?.schedule(after: self?.countInDuration ?? 0.5) { [weak self] in
                self?.beginListening(noteIndex: index)
            }
        }
    }

    private func beginListening(noteIndex: Int) {
        centsSamples = []
        audioEngine.startListening(owner: listenerID)
        phase = .listening(noteIndex: noteIndex)

        // Collect cents samples every 50ms
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.audioEngine.detectedFrequency != nil {
                Task { @MainActor in
                    self.centsSamples.append(abs(self.audioEngine.centsDeviation))
                }
            }
        }

        schedule(after: listeningDuration) { [weak self] in
            self?.endListeningPhase(noteIndex: noteIndex)
        }
    }

    private func endListeningPhase(noteIndex: Int) {
        sampleTimer?.invalidate()
        sampleTimer = nil
        phaseTimer?.invalidate()
        phaseTimer = nil

        audioEngine.stopListening(owner: listenerID)

        let meanAbsCents: Double
        if centsSamples.isEmpty {
            meanAbsCents = 100.0  // No detected pitch → fail
        } else {
            meanAbsCents = centsSamples.reduce(0, +) / Double(centsSamples.count)
        }

        let note = selectedScale.notes[noteIndex]
        let result = NoteResult(note: note, meanAbsCents: meanAbsCents)
        noteResults.append(result)

        let passed = result.passed
        phase = .gradingResult(noteIndex: noteIndex, passed: passed)

        schedule(after: gradingFlashDuration) { [weak self] in
            guard let self else { return }
            let nextIndex = noteIndex + 1
            if nextIndex < self.selectedScale.notes.count {
                self.advanceToNote(nextIndex)
            } else {
                self.finishExercise()
            }
        }
    }

    private func finishExercise() {
        let result = ExerciseResult(scaleName: selectedScale.name, noteResults: noteResults)
        phase = .complete(result)
        noteResults = []
    }

    // MARK: - Helpers

    private func schedule(after delay: TimeInterval, block: @escaping () -> Void) {
        phaseTimer?.invalidate()
        phaseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in block() }
        }
    }

    private func cancelTimers() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        sampleTimer?.invalidate()
        sampleTimer = nil
    }

    // MARK: - Computed Helpers for UI

    var currentNoteIndex: Int? {
        switch phase {
        case .playingReference(let i), .countIn(let i), .listening(let i), .gradingResult(let i, _):
            return i
        default:
            return nil
        }
    }

    var currentTargetNote: Note? {
        guard let i = currentNoteIndex else { return nil }
        return selectedScale.notes[i]
    }

    var isGaugeActive: Bool {
        if case .listening = phase { return true }
        return false
    }

    var statusText: String {
        switch phase {
        case .idle:                          return "Choose a scale to begin"
        case .playingReference:              return "Listen to the note..."
        case .countIn:                       return "Get ready..."
        case .listening:                     return "Sing!"
        case .gradingResult(_, let passed):  return passed ? "Passed!" : "Keep practicing!"
        case .complete:                      return "Exercise complete!"
        }
    }

    var gradingColor: Color? {
        if case .gradingResult(_, let passed) = phase {
            return passed ? .green : .red
        }
        return nil
    }

    var completedNoteCount: Int {
        noteResults.count
    }
}
