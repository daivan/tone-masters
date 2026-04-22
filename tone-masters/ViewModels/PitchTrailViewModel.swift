import SwiftUI
import Combine

struct PitchSample {
    let timestamp: Date
    let frequency: Double
}

@MainActor
final class PitchTrailViewModel: ObservableObject {
    @Published var samples: [PitchSample] = []
    @Published var isListening: Bool = false
    @Published var currentFrequency: Double? = nil
    @Published var currentNote: String? = nil

    let visibleWindowSeconds: Double = 6.0
    let silenceGapSeconds: TimeInterval = 0.15

    var midiLow: Double { settings.midiLow }
    var midiHigh: Double { settings.midiHigh }

    private let audioEngine: AudioEngine
    private let settings: VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var displayTimer: AnyCancellable?

    init(audioEngine: AudioEngine, settings: VoiceSettings) {
        self.audioEngine = audioEngine
        self.settings = settings
        observeAudioEngine()
    }

    // MARK: - Public

    func startListening() {
        audioEngine.targetFrequency = nil
        audioEngine.startListening(owner: listenerID)
        isListening = true

        displayTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.purgeStaleSamples()
            }
    }

    func stopListening() {
        audioEngine.stopListening(owner: listenerID)
        isListening = false
        displayTimer?.cancel()
        displayTimer = nil
        currentFrequency = nil
        currentNote = nil
    }

    func clearTrail() {
        samples.removeAll()
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

    // MARK: - Private

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
        let cutoff = Date.now.addingTimeInterval(-visibleWindowSeconds)
        samples.removeAll { $0.timestamp < cutoff }
    }
}
