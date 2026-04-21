import AVFoundation
import Accelerate
import Combine

@MainActor
final class AudioEngine: ObservableObject {
    @Published var detectedFrequency: Double? = nil
    @Published var detectedNote: String? = nil
    @Published var centsDeviation: Double = 0
    @Published var permissionGranted: Bool = false
    @Published var isListening: Bool = false

    // Shared AVAudioEngine — also used by ToneGenerator
    let avEngine = AVAudioEngine()

    // Target frequency hint for octave sanity check.
    // nonisolated(unsafe) allows read from background queue; writes always happen on MainActor.
    nonisolated(unsafe) var targetFrequency: Double? = nil

    private let analysisQueue = DispatchQueue(label: "com.tonemasters.pitch", qos: .userInitiated)
    nonisolated let sampleRate: Double = 44100
    private let bufferSize: AVAudioFrameCount = 4096
    nonisolated let yinWindowSize = 1024

    // MARK: - Permission & Lifecycle

    func requestPermission() async {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.permissionGranted = granted
                }
                continuation.resume()
            }
        }
    }

    func startEngine() throws {
        guard !avEngine.isRunning else { return }
        try configureAudioSession()
        try avEngine.start()
    }

    func startListening() {
        guard !isListening else { return }
        let inputNode = avEngine.inputNode

        // Pass nil format so AVAudioEngine uses the hardware's native format,
        // avoiding the 'IsFormatSampleRateAndChannelCountValid' crash when the
        // output format hasn't been resolved yet.
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { [weak self] buffer, _ in
            guard let self else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            var samples = [Float](repeating: 0, count: frameCount)
            memcpy(&samples, channelData, frameCount * MemoryLayout<Float>.size)
            let actualSampleRate = buffer.format.sampleRate
            let targetFreq = self.targetFrequency

            self.analysisQueue.async {
                let freq = self.runYIN(samples: samples,
                                      sampleRate: actualSampleRate,
                                      targetFrequency: targetFreq)
                let (noteName, cents) = freq.map { self.frequencyToNote($0) } ?? (nil, 0)

                Task { @MainActor in
                    self.detectedFrequency = freq
                    self.detectedNote = noteName
                    self.centsDeviation = cents
                }
            }
        }
        isListening = true
    }

    func stopListening() {
        guard isListening else { return }
        avEngine.inputNode.removeTap(onBus: 0)
        isListening = false
        detectedFrequency = nil
        detectedNote = nil
        centsDeviation = 0
    }

    // MARK: - Audio Session

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement,
                                options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    // MARK: - YIN Pitch Detection

    nonisolated func runYIN(samples: [Float], sampleRate: Double, targetFrequency: Double?) -> Double? {
        let count = min(samples.count, yinWindowSize)
        guard count >= 512 else { return nil }

        // Silence gate: RMS < 0.01 ≈ -40 dBFS
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(count))
        guard rms > 0.01 else { return nil }

        // Step 1: Difference function via autocorrelation
        // d[τ] = 2*r[0] - 2*r[τ]
        let acfLength = count * 2 - 1
        var acf = [Float](repeating: 0, count: acfLength)
        vDSP_conv(samples, 1, samples, 1, &acf, 1, vDSP_Length(acfLength), vDSP_Length(count))

        let r0 = acf[0]
        let tauMin = Int(ceil(sampleRate / 1100.0))  // ~40 at 44100 Hz
        let tauMax = min(Int(ceil(sampleRate / 80.0)), count / 2)  // ~552 at 44100 Hz

        var d = [Float](repeating: 0, count: tauMax + 1)
        for tau in 1...tauMax {
            d[tau] = 2 * r0 - 2 * acf[tau]
        }

        // Step 2: Cumulative mean normalized difference function
        var dp = [Float](repeating: 1.0, count: tauMax + 1)
        var cumSum: Float = 0
        for tau in 1...tauMax {
            cumSum += d[tau]
            dp[tau] = cumSum > 0 ? d[tau] * Float(tau) / cumSum : 1.0
        }

        // Step 3: Find first tau below threshold (or global min fallback)
        let threshold: Float = 0.15
        var bestTau = -1
        var bestVal: Float = Float.greatestFiniteMagnitude

        for tau in tauMin...tauMax {
            if dp[tau] < threshold {
                var t = tau
                while t + 1 <= tauMax && dp[t + 1] < dp[t] { t += 1 }
                bestTau = t
                break
            }
            if dp[tau] < bestVal {
                bestVal = dp[tau]
                bestTau = tau
            }
        }

        guard bestTau > 0, dp[bestTau] <= 0.3 else { return nil }

        // Step 4: Parabolic interpolation
        var refinedTau = Double(bestTau)
        if bestTau > tauMin && bestTau < tauMax {
            let y0 = Double(dp[bestTau - 1])
            let y1 = Double(dp[bestTau])
            let y2 = Double(dp[bestTau + 1])
            let denom = 2.0 * (y0 - 2.0 * y1 + y2)
            if abs(denom) > 1e-10 {
                refinedTau += (y0 - y2) / denom
            }
        }

        let detectedFreq = sampleRate / refinedTau

        // Octave sanity: discard if > 600 cents from expected note
        if let target = targetFrequency {
            let cents = 1200.0 * log2(detectedFreq / target)
            if abs(cents) > 600 { return nil }
        }

        return detectedFreq
    }

    // MARK: - Frequency → Note Name + Cents

    nonisolated func frequencyToNote(_ frequency: Double) -> (String?, Double) {
        guard frequency > 0 else { return (nil, 0) }
        let midiFloat = 69.0 + 12.0 * log2(frequency / 440.0)
        let nearestMidi = round(midiFloat)
        let cents = (midiFloat - nearestMidi) * 100.0

        let noteNames = ["C", "C#", "D", "D#", "E", "F",
                         "F#", "G", "G#", "A", "A#", "B"]
        let midi = Int(nearestMidi)
        let octave = (midi / 12) - 1
        let noteIndex = ((midi % 12) + 12) % 12
        let name = "\(noteNames[noteIndex])\(octave)"
        return (name, cents)
    }
}
