import Foundation
import Combine

@MainActor
final class VibratoViewModel: ObservableObject {
    @Published var vibratoHz: Double = 0
    @Published var isActive: Bool = false
    @Published var isInZone: Bool = false

    private let audioEngine: AudioEngine
    private let settings: VoiceSettings
    private let listenerID = UUID()

    private var recentPoints: [(midi: Double, date: Date)] = []
    private var sampleTimer: AnyCancellable?

    init(audioEngine: AudioEngine, settings: VoiceSettings) {
        self.audioEngine = audioEngine
        self.settings = settings
    }

    func start() {
        audioEngine.startListening(owner: listenerID)
        isActive = true

        sampleTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self else { return }
                if let freq = self.audioEngine.detectedFrequency, freq > 0 {
                    let midi = 12.0 * log2(freq / 440.0) + 69.0
                    self.recentPoints.append((midi: midi, date: now))
                }
                // Prune older than 2 seconds
                let cutoff = now.addingTimeInterval(-2.0)
                self.recentPoints.removeAll { $0.date < cutoff }
                self.updateVibrato()
            }
    }

    func stop() {
        audioEngine.stopListening(owner: listenerID)
        sampleTimer?.cancel()
        sampleTimer = nil
        recentPoints = []
        vibratoHz = 0
        isInZone = false
        isActive = false
    }

    private func updateVibrato() {
        guard recentPoints.count >= 10 else {
            vibratoHz = 0
            isInZone = false
            return
        }

        let midiValues = recentPoints.map { $0.midi }
        let mean = midiValues.reduce(0, +) / Double(midiValues.count)

        // Count zero-crossings of (midi - mean)
        var crossings = 0
        var prevSign = midiValues[0] - mean >= 0
        for val in midiValues.dropFirst() {
            let sign = val - mean >= 0
            if sign != prevSign {
                crossings += 1
            }
            prevSign = sign
        }

        let duration = recentPoints.last!.date.timeIntervalSince(recentPoints.first!.date)
        guard duration > 0.1 else { return }

        let hz = Double(crossings) / 2.0 / duration
        vibratoHz = hz
        isInZone = hz >= 5.0 && hz <= 7.0
    }

    var trailPoints: [(midi: Double, date: Date)] { recentPoints }
}
