import Foundation
import Combine

@MainActor
final class SpectrogramViewModel: ObservableObject {
    @Published var isActive: Bool = false

    private let audioEngine: AudioEngine
    private let listenerID = UUID()

    let sampleRate: Double = 44100
    let fftN: Int = 1024

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }

    func start() {
        audioEngine.startListening(owner: listenerID)
        isActive = true
    }

    func stop() {
        audioEngine.stopListening(owner: listenerID)
        isActive = false
    }

    var magnitudes: [Float] { audioEngine.spectrumMagnitudes }

    func frequency(forBin bin: Int) -> Double {
        Double(bin) * sampleRate / Double(fftN)
    }
}
