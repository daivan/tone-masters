import SwiftUI
import Combine

@MainActor
final class HissChallengeViewModel: ObservableObject {
    @Published var elapsed: TimeInterval = 0
    @Published var isHissing: Bool = false
    @Published var isActive: Bool = false
    @AppStorage("hiss_best") var bestTime: Double = 0

    private let audioEngine: AudioEngine
    private let listenerID = UUID()
    private var sampleTimer: AnyCancellable?
    private var hissStart: Date? = nil

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }

    func start() {
        audioEngine.startListening(owner: listenerID)
        isActive = true

        sampleTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self else { return }
                let hissDetected = self.audioEngine.micLevel > 0.04
                    && self.audioEngine.detectedFrequency == nil

                if hissDetected {
                    if !self.isHissing {
                        self.isHissing = true
                        self.hissStart = now
                    }
                    if let start = self.hissStart {
                        self.elapsed = now.timeIntervalSince(start)
                    }
                } else {
                    if self.isHissing {
                        // Hiss ended — save best
                        if self.elapsed > self.bestTime {
                            self.bestTime = self.elapsed
                        }
                        self.isHissing = false
                        self.hissStart = nil
                    }
                }
            }
    }

    func stop() {
        if isHissing && elapsed > bestTime {
            bestTime = elapsed
        }
        sampleTimer?.cancel()
        sampleTimer = nil
        audioEngine.stopListening(owner: listenerID)
        isHissing = false
        hissStart = nil
        isActive = false
    }

    func reset() {
        stop()
        elapsed = 0
    }
}
