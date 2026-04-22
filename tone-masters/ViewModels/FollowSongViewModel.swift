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

    // MARK: - Window constants
    let pastWindowSeconds:  Double = 2.0
    let futureWindowSeconds: Double = 6.0
    let totalWindowSeconds:  Double = 8.0
    let nowLineFraction:     CGFloat = 0.25
    let silenceGapSeconds:   TimeInterval = 0.15

    // MARK: - Pitch display range (auto-expands to fit song notes)
    var midiLow:  Double { min(settings.midiLow,  Double(currentSong.lowestMidi  - 2)) }
    var midiHigh: Double { max(settings.midiHigh, Double(currentSong.highestMidi + 2)) }

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
                self.displayTick &+= 1
                if self.phase == .playing && self.elapsed >= self.currentSong.totalDuration {
                    self.finishSong()
                }
            }
    }

    private func finishSong() {
        displayTimer?.cancel()
        displayTimer = nil
        audioEngine.stopListening(owner: listenerID)
        phase = .finished
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
