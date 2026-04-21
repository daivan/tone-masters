import SwiftUI
import Combine

@MainActor
final class FindYourRangeViewModel: ObservableObject {
    @Published var isListening: Bool = false
    @Published var currentNote: String? = nil
    @Published var currentFrequency: Double? = nil
    @Published var centsDeviation: Double = 0
    @Published var lowestMidi: Int? = nil
    @Published var highestMidi: Int? = nil

    private let audioEngine: AudioEngine
    private var cancellables = Set<AnyCancellable>()

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
        observeAudioEngine()
    }

    // MARK: - Public

    func startListening() {
        audioEngine.targetFrequency = nil  // no octave sanity guard in free mode
        audioEngine.startListening()
        isListening = true
    }

    func stopListening() {
        audioEngine.stopListening()
        isListening = false
    }

    func reset() {
        stopListening()
        lowestMidi = nil
        highestMidi = nil
        currentNote = nil
        currentFrequency = nil
        centsDeviation = 0
    }

    // MARK: - Computed

    var lowestNoteName: String? {
        guard let midi = lowestMidi else { return nil }
        return noteName(for: midi)
    }

    var highestNoteName: String? {
        guard let midi = highestMidi else { return nil }
        return noteName(for: midi)
    }

    var rangeDescription: String? {
        guard let low = lowestNoteName, let high = highestNoteName else { return nil }
        if low == high { return low }
        return "\(low) – \(high)"
    }

    // MARK: - Private

    private func observeAudioEngine() {
        audioEngine.$detectedFrequency
            .receive(on: RunLoop.main)
            .sink { [weak self] freq in
                guard let self else { return }
                self.currentFrequency = freq
                if let freq {
                    self.updateRange(frequency: freq)
                }
            }
            .store(in: &cancellables)

        audioEngine.$detectedNote
            .receive(on: RunLoop.main)
            .sink { [weak self] note in
                self?.currentNote = note
            }
            .store(in: &cancellables)

        audioEngine.$centsDeviation
            .receive(on: RunLoop.main)
            .sink { [weak self] cents in
                self?.centsDeviation = cents
            }
            .store(in: &cancellables)
    }

    private func updateRange(frequency: Double) {
        let midiFloat = 69.0 + 12.0 * log2(frequency / 440.0)
        let midi = Int(round(midiFloat))

        if lowestMidi == nil || midi < lowestMidi! {
            lowestMidi = midi
        }
        if highestMidi == nil || midi > highestMidi! {
            highestMidi = midi
        }
    }

    private func noteName(for midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F",
                     "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midi / 12) - 1
        let index = ((midi % 12) + 12) % 12
        return "\(names[index])\(octave)"
    }
}
