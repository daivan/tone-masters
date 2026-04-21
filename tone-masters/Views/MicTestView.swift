import SwiftUI

struct MicTestView: View {
    @ObservedObject var audioEngine: AudioEngine
    @Environment(\.dismiss) private var dismiss
    @State private var isTesting = false
    @State private var micPulse: Double = 1.0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Status icon
            Image(systemName: isTesting ? "mic.fill" : "mic.slash.fill")
                .font(.system(size: 56))
                .foregroundStyle(isTesting ? .blue : .secondary)
                .opacity(isTesting ? micPulse : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: micPulse)
                .onAppear { if isTesting { micPulse = 0.4 } }
                .onChange(of: isTesting) { active in micPulse = active ? 0.4 : 1.0 }

            // Level bar
            VStack(spacing: 12) {
                Text("MICROPHONE LEVEL")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(2)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.15))

                        // Level fill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(levelColor)
                            .frame(width: geo.size.width * CGFloat(audioEngine.micLevel))
                            .animation(.easeOut(duration: 0.05), value: audioEngine.micLevel)
                    }
                }
                .frame(height: 28)
                .padding(.horizontal, 24)

                // dB readout
                Text(isTesting ? String(format: "%.1f dBFS", audioEngine.micLevelDB) : "—")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(isTesting ? .primary : .secondary)
                    .monospacedDigit()
            }

            // What the numbers mean
            VStack(spacing: 6) {
                levelHint(range: "–60 dBFS", meaning: "Silence / no input", color: .secondary)
                levelHint(range: "–40 to –20 dBFS", meaning: "Quiet room / whisper", color: .yellow)
                levelHint(range: "–20 to –6 dBFS", meaning: "Normal singing voice", color: .green)
                levelHint(range: "Above –6 dBFS", meaning: "Very loud / close to clipping", color: .red)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Start / Stop
            Button {
                if isTesting {
                    audioEngine.stopMicTest()
                } else {
                    audioEngine.startMicTest()
                }
                isTesting.toggle()
            } label: {
                Label(
                    isTesting ? "Stop Test" : "Start Mic Test",
                    systemImage: isTesting ? "stop.fill" : "mic.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isTesting ? .red : .blue)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Microphone Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if isTesting {
                audioEngine.stopMicTest()
                isTesting = false
            }
        }
    }

    private var levelColor: Color {
        let db = audioEngine.micLevelDB
        if db > -6  { return .red }
        if db > -20 { return .green }
        if db > -40 { return .yellow }
        return .secondary
    }

    private func levelHint(range: String, meaning: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(range)
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 140, alignment: .leading)
            Text(meaning)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
