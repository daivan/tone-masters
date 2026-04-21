import SwiftUI

struct FindYourRangeView: View {
    @ObservedObject var viewModel: FindYourRangeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Detected note display
            VStack(spacing: 8) {
                Text("SINGING")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(2)
                    .opacity(viewModel.isListening ? 1 : 0)

                if let note = viewModel.currentNote {
                    Text(note)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.1), value: note)
                } else {
                    Text(viewModel.isListening ? "—" : "Tap to start")
                        .font(.system(size: viewModel.isListening ? 96 : 32,
                                      weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.isListening ? .primary : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isListening)
                }

                if let freq = viewModel.currentFrequency {
                    Text(String(format: "%.1f Hz", freq))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .transition(.opacity)
                } else {
                    Text(" ")
                        .font(.subheadline)
                }
            }
            .frame(height: 160)

            Spacer().frame(height: 32)

            // Tuner gauge
            TunerGaugeView(
                centsDeviation: viewModel.centsDeviation,
                isActive: viewModel.isListening && viewModel.currentNote != nil
            )

            Spacer().frame(height: 40)

            // Range summary
            rangeSection

            Spacer()

            // Start / Stop button
            Button {
                if viewModel.isListening {
                    viewModel.stopListening()
                } else {
                    viewModel.startListening()
                }
            } label: {
                Label(
                    viewModel.isListening ? "Stop" : "Start Listening",
                    systemImage: viewModel.isListening ? "stop.fill" : "mic.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(viewModel.isListening ? .red : .blue)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Reset button (only when range has been captured)
            if viewModel.lowestMidi != nil {
                Button("Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .padding(.bottom, 32)
            } else {
                Spacer().frame(height: 64)
            }
        }
        .navigationTitle("Find Your Range")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // MARK: - Range Summary

    @ViewBuilder
    private var rangeSection: some View {
        if let range = viewModel.rangeDescription {
            VStack(spacing: 6) {
                Text("DETECTED RANGE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(2)

                Text(range)
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .animation(.easeInOut(duration: 0.2), value: range)

                if let low = viewModel.lowestNoteName, let high = viewModel.highestNoteName,
                   low != high {
                    Text("lowest · highest")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 32)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)
        } else if viewModel.isListening {
            Text("Sing a note to detect your range")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            EmptyView()
        }
    }
}
