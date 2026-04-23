import SwiftUI
import Combine

enum SongPhase {
    case idle, playing, finished
}

@MainActor
final class FollowSongViewModel: ObservableObject {
    // MARK: - Published
    @Published var phase: SongPhase = .idle
    @Published var currentSong: Song = SongLibrary.twinkleTwinkle
    @Published var samples: [PitchSample] = []
    @Published var currentFrequency: Double? = nil
    @Published var currentNote: String? = nil
    @Published var displayTick: Int = 0
    @Published var finalScores: [NoteScore] = []

    // MARK: - Score data (keyed by SongNote.id)
    private var noteScoreData: [UUID: (hit: Int, total: Int)] = [:]

    // MARK: - Window constants
    let pastWindowSeconds:  Double = 2.0
    let futureWindowSeconds: Double = 6.0
    let totalWindowSeconds:  Double = 8.0
    let nowLineFraction:     CGFloat = 0.25
    let silenceGapSeconds:   TimeInterval = 0.15

    // MARK: - Transposition
    // Shifts the whole song so its midpoint lands on the user's center note.
    var transpositionOffset: Int { settings.centerMidi - currentSong.naturalCenterMidi }

    func transposedMidi(for note: SongNote) -> Int { note.midiNote + transpositionOffset }

    // MARK: - Pitch display range (based on transposed song range)
    var midiLow:  Double { min(settings.midiLow,  Double(currentSong.lowestMidi  + transpositionOffset - 2)) }
    var midiHigh: Double { max(settings.midiHigh, Double(currentSong.highestMidi + transpositionOffset + 2)) }

    // MARK: - Dependencies
    private let audioEngine: AudioEngine
    private let settings: VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var displayTimer: AnyCancellable?

    // MARK: - Timing
    private var startDate: Date? = nil

    var elapsed: Double {
        switch phase {
        case .idle:     return 0
        case .finished: return currentSong.totalDuration
        case .playing:
            guard let start = startDate else { return 0 }
            return Date.now.timeIntervalSince(start)
        }
    }

    init(audioEngine: AudioEngine, settings: VoiceSettings) {
        self.audioEngine = audioEngine
        self.settings = settings
        observeAudioEngine()
    }

    // MARK: - Controls

    func start() {
        samples = []
        startDate = Date.now
        phase = .playing
        audioEngine.targetFrequency = nil
        audioEngine.startListening(owner: listenerID)
        startDisplayTimer()
    }

    func stop() {
        displayTimer?.cancel()
        displayTimer = nil
        audioEngine.stopListening(owner: listenerID)
        startDate = nil
        samples = []
        noteScoreData = [:]
        finalScores = []
        phase = .idle
        currentFrequency = nil
        currentNote = nil
    }

    func restart() {
        stop()
        start()
    }

    func stopListening() {
        displayTimer?.cancel()
        displayTimer = nil
        audioEngine.stopListening(owner: listenerID)
    }

    // MARK: - Helpers

    func frequencyToMidi(_ frequency: Double) -> Double {
        69.0 + 12.0 * log2(frequency / 440.0)
    }

    func noteName(for midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F",
                     "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midi / 12) - 1
        let index = ((midi % 12) + 12) % 12
        return "\(names[index])\(octave)"
    }

    func hitRate(for note: SongNote) -> Double {
        let d = noteScoreData[note.id] ?? (hit: 0, total: 0)
        return d.total > 0 ? Double(d.hit) / Double(d.total) : 0
    }

    func isCurrentlyHitting(targetMidi: Int) -> Bool {
        guard let freq = currentFrequency else { return false }
        return abs(frequencyToMidi(freq) - Double(targetMidi)) <= 1.5
    }

    var overallScore: Int {
        guard !finalScores.isEmpty else { return 0 }
        let passed = finalScores.filter(\.passed).count
        return Int(Double(passed) / Double(finalScores.count) * 100)
    }

    /// Cents deviation from the active target note (nil during rests or silence).
    var centsFromTarget: Double? {
        guard let freq = currentFrequency, let note = activeNote else { return nil }
        return (frequencyToMidi(freq) - Double(transposedMidi(for: note))) * 100.0
    }

    /// The note whose window contains the current elapsed time (nil during rests).
    var activeNote: SongNote? {
        let e = elapsed
        return currentSong.notes.first {
            e >= $0.startTime(bpm: currentSong.bpm) && e < $0.endTime(bpm: currentSong.bpm)
        }
    }

    func timeString(_ seconds: Double) -> String {
        let s = Int(max(0, seconds))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: - Private

    private func startDisplayTimer() {
        displayTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.purgeStaleSamples()
                self.scoreCurrentFrame()
                self.displayTick &+= 1
                if self.phase == .playing && self.elapsed >= self.currentSong.totalDuration {
                    self.finishSong()
                }
            }
    }

    private func finishSong() {
        finalScores = currentSong.notes.map { note in
            let d = noteScoreData[note.id] ?? (hit: 0, total: 0)
            return NoteScore(note: note, hitFrames: d.hit, totalFrames: d.total)
        }
        displayTimer?.cancel()
        displayTimer = nil
        audioEngine.stopListening(owner: listenerID)
        phase = .finished
    }

    private func scoreCurrentFrame() {
        let e = elapsed
        for note in currentSong.notes {
            let start = note.startTime(bpm: currentSong.bpm)
            let end   = note.endTime(bpm: currentSong.bpm)
            guard e >= start && e < end else { continue }
            noteScoreData[note.id, default: (hit: 0, total: 0)].total += 1
            if let freq = currentFrequency {
                let userMidi = frequencyToMidi(freq)
                let targetMidi = Double(transposedMidi(for: note))
                if abs(userMidi - targetMidi) <= 1.5 {
                    noteScoreData[note.id, default: (hit: 0, total: 0)].hit += 1
                }
            }
            break  // only one note active at a time
        }
    }

    private func observeAudioEngine() {
        audioEngine.$detectedFrequency
            .receive(on: RunLoop.main)
            .sink { [weak self] (freq: Double?) in
                guard let self else { return }
                self.currentFrequency = freq
                if let freq {
                    self.samples.append(PitchSample(timestamp: .now, frequency: freq))
                }
            }
            .store(in: &cancellables)

        audioEngine.$detectedNote
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                self?.currentNote = note
            }
            .store(in: &cancellables)
    }

    private func purgeStaleSamples() {
        let cutoff = Date.now.addingTimeInterval(-pastWindowSeconds)
        samples.removeAll { $0.timestamp < cutoff }
    }
}
