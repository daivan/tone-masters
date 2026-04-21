import AVFoundation

final class ToneGenerator {
    private let engine: AVAudioEngine

    // Audio-thread state — written from render callback (real-time thread)
    // and from main thread via play/stop; protected by the fact that we only
    // write targetFrequency/targetAmplitude from non-realtime context and
    // the render callback only reads them.
    private var phase: Double = 0
    private var targetFrequency: Double = 440
    private var targetAmplitude: Double = 0
    private var currentAmplitude: Double = 0
    private let rampFrames: Double = 441  // 10ms at 44100 Hz

    init(engine: AVAudioEngine) {
        self.engine = engine
        attachNode(to: engine)
    }

    func play(frequency: Double) {
        targetFrequency = frequency
        targetAmplitude = 0.5
    }

    func stop() {
        targetAmplitude = 0
    }

    // MARK: - Private

    private func attachNode(to engine: AVAudioEngine) {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = ablPointer.first?.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }

            let freq = self.targetFrequency
            let ramp = self.rampFrames

            for frame in 0..<Int(frameCount) {
                let diff = self.targetAmplitude - self.currentAmplitude
                if abs(diff) > 0.0001 {
                    self.currentAmplitude += diff / ramp
                } else {
                    self.currentAmplitude = self.targetAmplitude
                }

                let sample = Float(self.currentAmplitude * sin(2.0 * .pi * self.phase))
                buffer[frame] = sample

                self.phase += freq / 44100.0
                if self.phase >= 1.0 { self.phase -= 1.0 }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
    }
}
