import SwiftUI

struct ExerciseView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showScore = false
    @State private var completedResult: ExerciseResult? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            progressDots
                .padding(.top, 16)
                .padding(.bottom, 24)

            // Target note display
            targetNoteDisplay
                .padding(.bottom, 32)

            // Tuner gauge
            TunerGaugeView(
                centsDeviation: viewModel.currentCentsDeviation,
                isActive: viewModel.isGaugeActive
            )
            .padding(.bottom, 16)

            // Live detection label
            detectionLabel
                .frame(height: 24)
                .padding(.bottom, 32)

            Spacer()

            // Status text + action button
            VStack(spacing: 20) {
                statusLabel

                actionButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle(viewModel.selectedScale.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            viewModel.cleanup()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.restartExercise()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .background(gradingBackground.ignoresSafeArea())
        .sheet(isPresented: $showScore) {
            if let result = completedResult {
                ScoreView(
                    result: result,
                    onTryAgain: {
                        showScore = false
                        viewModel.startExercise()
                    },
                    onChooseScale: {
                        showScore = false
                        viewModel.restartExercise()
                        dismiss()
                    }
                )
            }
        }
        .onChange(of: viewModel.phase) { newPhase in
            if case .complete(let result) = newPhase {
                completedResult = result
                showScore = true
            }
        }
        .task {
            viewModel.startExercise()
        }
    }

    // MARK: - Subviews

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.selectedScale.notes.count, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentNoteIndex)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        guard let currentIndex = viewModel.currentNoteIndex else {
            return Color.secondary.opacity(0.3)
        }
        if index < currentIndex { return .green }
        if index == currentIndex { return .primary }
        return Color.secondary.opacity(0.3)
    }

    private var targetNoteDisplay: some View {
        VStack(spacing: 6) {
            Text("TARGET NOTE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(2)

            if let note = viewModel.currentTargetNote {
                Text(note.name)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: note.name)

                Text(String(format: "%.2f Hz", note.frequency))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text("—")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detectionLabel: some View {
        Group {
            if viewModel.isGaugeActive, let noteName = viewModel.currentDetectedNote {
                let cents = viewModel.currentCentsDeviation
                let sign = cents >= 0 ? "+" : ""
                Text("Detected: \(noteName)  (\(sign)\(Int(cents))¢)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else {
                Text(" ") // Keep height stable
                    .font(.subheadline)
            }
        }
    }

    private var statusLabel: some View {
        Text(viewModel.statusText)
            .font(.title3.weight(.medium))
            .foregroundStyle(statusColor)
            .animation(.easeInOut(duration: 0.2), value: viewModel.statusText)
    }

    private var statusColor: Color {
        if let grading = viewModel.gradingColor { return grading }
        return .primary
    }

    private var actionButton: some View {
        Button {
            viewModel.skipNote()
        } label: {
            Text(buttonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(!viewModel.isGaugeActive)
    }

    private var buttonLabel: String {
        switch viewModel.phase {
        case .idle:                    return "Start"
        case .playingReference:        return "Listening to reference..."
        case .countIn:                 return "Get ready..."
        case .listening:               return "Skip"
        case .gradingResult:           return "Next..."
        case .complete:                return "Done"
        }
    }

    private var gradingBackground: some View {
        (viewModel.gradingColor ?? .clear)
            .opacity(viewModel.gradingColor != nil ? 0.08 : 0)
            .animation(.easeInOut(duration: 0.3), value: viewModel.gradingColor)
    }
}
