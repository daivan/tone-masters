import Foundation
import Combine

@MainActor
final class PitchCharacterViewModel: ObservableObject {
    @Published var characterFraction: Double = 0.5
    @Published var currentNote: String? = nil
    @Published var isActive: Bool = false

    private let audioEngine: AudioEngine
    private let settings: VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()

    init(audioEngine: AudioEngine, settings: VoiceSettings) {
        self.audioEngine = audioEngine
        self.settings = settings
    }

    func start() {
        audioEngine.startListening(owner: listenerID)
        isActive = true

        audioEngine.$detectedFrequency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] freq in
                guard let self else { return }
                guard let freq, freq > 0 else { return }
                let midi = 12.0 * log2(freq / 440.0) + 69.0
                let low = self.settings.midiLow
                let high = self.settings.midiHigh
                let range = high - low
                guard range > 0 else { return }
                let fraction = (midi - low) / range
                self.characterFraction = max(0, min(1, fraction))
            }
            .store(in: &cancellables)

        audioEngine.$detectedNote
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                self?.currentNote = note
            }
            .store(in: &cancellables)
    }

    func stop() {
        audioEngine.stopListening(owner: listenerID)
        cancellables.removeAll()
        isActive = false
    }
}
