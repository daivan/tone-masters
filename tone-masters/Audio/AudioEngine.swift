import AVFoundation
import Accelerate
import Combine
import os

@MainActor
final class AudioEngine: ObservableObject {
    @Published var detectedFrequency: Double? = nil
    @Published var detectedNote: String? = nil
    @Published var centsDeviation: Double = 0
    @Published var permissionGranted: Bool = false
    @Published var isListening: Bool = false
    @Published var micLevel: Float = 0       // 0.0 – 1.0 RMS, updated in any tap mode
    @Published var micLevelDB: Float = -60   // dBFS, roughly -60 (silence) to 0

    // Shared AVAudioEngine — also used by ToneGenerator
    let avEngine = AVAudioEngine()

    // Target frequency hint for octave sanity check.
    // Lock-protected so it's safe to write from @MainActor and read from the audio tap thread.
    private let _targetFreqLock = OSAllocatedUnfairLock<Double?>(initialState: nil)
    nonisolated var targetFrequency: Double? {
        get { _targetFreqLock.withLock { $0 } }
        set { _targetFreqLock.withLock { $0 = newValue } }
    }

    // Tracks which ViewModel currently owns the mic tap.
    private var listenerOwnerID: UUID? = nil

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

    func startListening(owner: UUID) {
        if listenerOwnerID == owner { return }  // already our tap
        // Evict any previous owner's tap cleanly before installing a new one
        if isListening {
            avEngine.inputNode.removeTap(onBus: 0)
            detectedFrequency = nil
            detectedNote = nil
            centsDeviation = 0
        }
        listenerOwnerID = owner
        installTap(pitchDetection: true)
        isListening = true
    }

    func stopListening(owner: UUID) {
        guard listenerOwnerID == owner else { return }  // not your tap to stop
        listenerOwnerID = nil
        removeTap()
    }

    // MARK: - Mic Test (level-only tap, no pitch detection)

    func startMicTest() {
        guard !isListening else { return }
        if !avEngine.isRunning {
            try? startEngine()
        }
        installTap(pitchDetection: false)
        isListening = true
    }

    func stopMicTest() {
        listenerOwnerID = nil
        removeTap()
    }

    private func removeTap() {
        avEngine.inputNode.removeTap(onBus: 0)
        isListening = false
        detectedFrequency = nil
        detectedNote = nil
        centsDeviation = 0
        micLevel = 0
        micLevelDB = -60
    }

    // MARK: - Shared tap installer

    private func installTap(pitchDetection: Bool) {
        // AVAudioEngine compiles its graph on start(). If inputNode had no tap at that
        // point the hardware mic path is never opened and all tap buffers are silent.
        // Stopping before installing forces the graph to recompile with inputNode active.
        // stop() preserves all node attachments and connections (ToneGenerator stays wired).
        let wasRunning = avEngine.isRunning
        if wasRunning { avEngine.stop() }

        let inputNode = avEngine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        let tapFormat: AVAudioFormat? = hwFormat.sampleRate > 0 ? hwFormat : nil

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, _ in
            guard let self else { return }

            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }

            // Extract mono float samples regardless of channel layout
            let samples: [Float]
            if let floatData = buffer.floatChannelData {
                // Non-interleaved float (most common on iOS)
                var s = [Float](repeating: 0, count: frameCount)
                memcpy(&s, floatData[0], frameCount * MemoryLayout<Float>.size)
                samples = s
            } else if let int16Data = buffer.int16ChannelData {
                // Interleaved 16-bit — convert to float
                var s = [Float](repeating: 0, count: frameCount)
                vDSP_vflt16(int16Data[0], 1, &s, 1, vDSP_Length(frameCount))
                var scale: Float = 1.0 / 32768.0
                vDSP_vsmul(s, 1, &scale, &s, 1, vDSP_Length(frameCount))
                samples = s
            } else {
                return  // Unknown format — skip
            }

            let actualSampleRate = buffer.format.sampleRate
            let targetFreq = self.targetFrequency

            self.analysisQueue.async {
                let rms = self.computeRMS(samples: samples, count: frameCount)

                if pitchDetection {
                    let freq = self.runYIN(samples: samples,
                                          sampleRate: actualSampleRate,
                                          targetFrequency: targetFreq)
                    let (noteName, cents) = freq.map { self.frequencyToNote($0) } ?? (nil, 0)
                    Task { @MainActor in
                        self.updateMicLevel(rms: rms)
                        self.detectedFrequency = freq
                        self.detectedNote = noteName
                        self.centsDeviation = cents
                    }
                } else {
                    Task { @MainActor in
                        self.updateMicLevel(rms: rms)
                    }
                }
            }
        }

        // Restart so the newly-tapped inputNode is part of the active graph.
        if wasRunning { try? avEngine.start() }
    }


    // MARK: - Audio Session

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        // .default mode (not .measurement) lets the iPhone activate its mic normally for voice input.
        // .measurement disables AGC/processing but can prevent the mic from capturing voice on device.
        try session.setCategory(.playAndRecord, mode: .default,
                                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
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

    // MARK: - Mic Level Helpers

    nonisolated func computeRMS(samples: [Float], count: Int) -> Float {
        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(count))
        return rms
    }

    // Must be called on MainActor
    func updateMicLevel(rms: Float) {
        micLevel = min(rms * 10, 1.0)   // scale up — typical voice RMS is 0.01–0.1
        let db = rms > 0 ? 20 * log10(rms) : -60
        micLevelDB = max(db, -60)
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
