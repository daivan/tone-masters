import SwiftUI

struct HissChallengeView: View {
    @ObservedObject var viewModel: HissChallengeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart = Date()

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                Spacer()
                timerDisplay
                Spacer()
                instructionCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            sessionStart = Date()
            RestReminderManager.shared.scheduleReminder()
        }
        .onDisappear {
            RestReminderManager.shared.cancelReminder()
            DailyLimitManager.shared.recordSession(seconds: Date().timeIntervalSince(sessionStart))
            viewModel.stop()
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tmInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
            }
            Spacer()
            Text("BREATH HISS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .kerning(1.4)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Timer display

    private var timerDisplay: some View {
        let best = viewModel.bestTime
        let elapsed = viewModel.elapsed
        let ringFraction: Double = best > 0 ? min(1.0, elapsed / best) : min(1.0, elapsed / 30.0)

        return VStack(spacing: 20) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.tmDimmer, lineWidth: 12)
                    .frame(width: 180, height: 180)

                // Progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(ringFraction))
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .foregroundStyle(viewModel.isHissing ? Color.tmAccent : Color.tmDimmer)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.1), value: ringFraction)

                // Timer text
                VStack(spacing: 4) {
                    Text(timerString(elapsed))
                        .font(.system(size: 52, weight: .light, design: .serif).italic())
                        .foregroundStyle(viewModel.isHissing ? Color.tmAccent : Color.tmDim)
                        .monospacedDigit()

                    Text("Best: \(String(format: "%.1f", viewModel.bestTime))s")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
            }

            Text(statusText)
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(statusColor)
                .kerning(0.5)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isHissing)
        }
    }

    private func timerString(_ t: TimeInterval) -> String {
        let seconds = Int(t)
        let tenths = Int((t - Double(seconds)) * 10)
        return String(format: "%02d.%d", seconds, tenths)
    }

    private var statusText: String {
        guard viewModel.isActive else { return "Ready — breathe in" }
        if viewModel.isHissing { return "Keep going!" }
        return "Hiss steadily and hold…"
    }

    private var statusColor: Color {
        viewModel.isHissing ? Color.tmAccent : Color.tmDim
    }

    // MARK: - Instruction card

    private var instructionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.tmDim)
                .frame(width: 24)
            Text("Breathe in slowly, then produce a steady 'ssss' hiss. The timer runs as long as non-pitched sound is detected.")
                .font(.system(size: 13))
                .foregroundStyle(Color.tmDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tmLine, lineWidth: 1))
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        HStack(spacing: 12) {
            if viewModel.isActive {
                Button("Reset") { viewModel.reset() }
                    .buttonStyle(TmSecondaryButtonStyle())
                Button("Stop") { viewModel.stop() }
                    .buttonStyle(TmSecondaryButtonStyle())
            } else {
                Button("Reset") { viewModel.elapsed = 0 }
                    .buttonStyle(TmSecondaryButtonStyle())
                Button("Start") { viewModel.start() }
                    .buttonStyle(TmPrimaryButtonStyle())
            }
        }
    }
}
