import SwiftUI
import Combine

// MARK: - Vocal register

enum VocalRegister {
    case chest, mix, head

    /// Approximate color for the trail segment
    var color: Color {
        switch self {
        case .chest: return Color(red: 0.88, green: 0.55, blue: 0.28)  // amber
        case .mix:   return Color.tmAccent                              // mint
        case .head:  return Color(red: 0.55, green: 0.62, blue: 0.92)  // soft violet-blue
        }
    }

    var label: String {
        switch self {
        case .chest: return "Chest"
        case .mix:   return "Mix"
        case .head:  return "Head"
        }
    }
}

// MARK: - Phase

enum SirenPhase {
    case idle, active, complete
}

// MARK: - ViewModel

@MainActor
final class SirenViewModel: ObservableObject {
    @Published var phase: SirenPhase = .idle
    @Published var samples: [PitchSample] = []
    @Published var currentFrequency: Double? = nil
    @Published var guideProgress: Double = 0   // 0 = low, 1 = high
    @Published var isAscending: Bool = true

    // Configurable sweep duration (each direction)
    let sweepDuration: TimeInterval = 10.0
    var totalDuration: TimeInterval { sweepDuration * 2 }

    private let audioEngine: AudioEngine
    private let settings: VoiceSettings
    private let listenerID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var displayTimer: AnyCancellable?
    private var startDate: Date?

    // MARK: - Range / register helpers

    var midiLow:  Double { Double(settings.centerMidi - 12) }
    var midiHigh: Double { Double(settings.centerMidi + 12) }
    var centerMidi: Int  { settings.centerMidi }

    /// MIDI below which we consider chest voice (≈ center − 4 semitones)
    var chestCeiling: Double { Double(settings.centerMidi - 4) }
    /// MIDI above which we consider head voice (≈ center + 4 semitones)
    var headFloor: Double    { Double(settings.centerMidi + 4) }

    /// The MIDI pitch of the current guide line position.
    var guideMidi: Double { midiLow + guideProgress * (midiHigh - midiLow) }

    var elapsed: Double {
        guard let start = startDate else { return 0 }
        return Date.now.timeIntervalSince(start)
    }

    init(audioEngine: AudioEngine, settings: VoiceSettings) {
        self.audioEngine = audioEngine
        self.settings    = settings
        observeAudioEngine()
    }

    // MARK: - Controls

    func start() {
        samples      = []
        guideProgress = 0
        isAscending  = true
        startDate    = Date.now
        phase        = .active
        audioEngine.startListening(owner: listenerID)
        startTimer()
    }

    func stop() {
        displayTimer?.cancel()
        displayTimer = nil
        audioEngine.stopListening(owner: listenerID)
        startDate    = nil
        samples      = []
        guideProgress = 0
        phase        = .idle
        currentFrequency = nil
    }

    func restart() {
        stop()
        start()
    }

    // MARK: - Register classification

    func register(forMidi midi: Double) -> VocalRegister {
        if midi < chestCeiling { return .chest }
        if midi > headFloor    { return .head }
        return .mix
    }

    func currentRegister() -> VocalRegister? {
        guard let freq = currentFrequency else { return nil }
        let midi = 69.0 + 12.0 * log2(freq / 440.0)
        return register(forMidi: midi)
    }

    func frequencyToMidi(_ frequency: Double) -> Double {
        69.0 + 12.0 * log2(frequency / 440.0)
    }

    // MARK: - Private

    private func startTimer() {
        displayTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let e = elapsed
        if e >= totalDuration {
            phase = .complete
            displayTimer?.cancel()
            displayTimer = nil
            audioEngine.stopListening(owner: listenerID)
            return
        }

        if e < sweepDuration {
            isAscending   = true
            guideProgress = e / sweepDuration
        } else {
            isAscending   = false
            guideProgress = 1.0 - (e - sweepDuration) / sweepDuration
        }
    }

    private func observeAudioEngine() {
        audioEngine.$detectedFrequency
            .receive(on: RunLoop.main)
            .sink { [weak self] freq in
                guard let self else { return }
                self.currentFrequency = freq
                if let freq {
                    self.samples.append(PitchSample(timestamp: .now, frequency: freq))
                }
            }
            .store(in: &cancellables)
    }
}
