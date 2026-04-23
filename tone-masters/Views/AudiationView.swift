import SwiftUI

struct AudiationView: View {
    @ObservedObject var viewModel: AudiationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart = Date()

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                Spacer()
                progressDots
                    .padding(.bottom, 32)
                noteDisplay
                Spacer()
                phaseIndicator
                Spacer()
                actionArea
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarHidden(true)
        .onAppear  { sessionStart = Date(); RestReminderManager.shared.scheduleReminder() }
        .onDisappear {
            RestReminderManager.shared.cancelReminder()
            DailyLimitManager.shared.recordSession(seconds: Date().timeIntervalSince(sessionStart))
            viewModel.cleanup()
        }
        .task { viewModel.start() }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button {
                viewModel.restart()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.tmInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
            }
            Spacer()
            Text("Audiation")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.2)
            Spacer()
            // Placeholder to balance
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.notes.count, id: \.self) { i in
                Circle()
                    .fill(dotColor(for: i))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentNoteIndex)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        guard let current = viewModel.currentNoteIndex else { return Color.tmDimmer }
        if index < current  { return .tmGood }
        if index == current { return .tmAccent }
        return Color.tmDimmer
    }

    // MARK: - Note name display

    private var noteDisplay: some View {
        VStack(spacing: 8) {
            Text("TARGET NOTE")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .kerning(1.4)

            if let name = viewModel.currentNoteName {
                Text(name)
                    .font(.system(size: 96, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmInk)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: name)
            } else {
                Text("—")
                    .font(.system(size: 96, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmDimmer)
            }

            // Reveal result below the note name
            if let result = viewModel.resultForCurrentNote {
                resultBadge(result)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: viewModel.resultForCurrentNote != nil)
    }

    private func resultBadge(_ result: AudiationNoteResult) -> some View {
        let cents = Int(result.meanAbsCents)
        return HStack(spacing: 8) {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(result.passed ? Color.tmGood : Color.tmWarn)
            Text("±\(cents)¢ average")
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(Color.tmInk)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
            result.passed ? Color.tmGood.opacity(0.4) : Color.tmWarn.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Phase indicator

    private var phaseIndicator: some View {
        VStack(spacing: 20) {
            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .playingTone:
                listeningWave

            case .countIn(_, let count):
                Text("\(count)")
                    .font(.system(size: 72, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmAccent)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: count)

            case .singing:
                singingPulse

            case .revealing(_, let passed):
                Text(passed ? "Well done!" : "Keep going!")
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(passed ? Color.tmGood : Color.tmWarn)

            case .complete:
                EmptyView()
            }

            // Phase label
            Text(viewModel.phaseLabel)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.0)
                .opacity(showingLabel ? 1 : 0)
        }
    }

    private var showingLabel: Bool {
        switch viewModel.phase {
        case .countIn, .singing, .revealing: return false
        case .playingTone: return true
        default: return true
        }
    }

    // Animated bars for "listening" phase
    private var listeningWave: some View {
        LiveBarsView(color: .tmAccent, dimColor: .tmDimmer, count: 20, height: 48)
            .frame(width: 180, height: 48)
    }

    // Pulsing mic icon for "sing" phase
    private var singingPulse: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let scale = 1.0 + 0.08 * sin(t * 3.0)
            ZStack {
                Circle()
                    .fill(Color.tmAccent.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .scaleEffect(1.0 + 0.15 * abs(sin(t * 1.5)))
                Circle()
                    .fill(Color.tmAccent)
                    .frame(width: 64, height: 64)
                    .scaleEffect(scale)
                Image(systemName: "mic.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.tmAccentInk)
            }
        }
    }

    // MARK: - Action area

    private var actionArea: some View {
        Group {
            switch viewModel.phase {
            case .complete(let result):
                completionView(result)

            case .revealing:
                Button("Next note") { viewModel.proceedFromReveal() }
                    .buttonStyle(TmPrimaryButtonStyle())

            case .singing:
                Button("Skip") { viewModel.skip() }
                    .buttonStyle(TmSecondaryButtonStyle())

            default:
                Color.clear.frame(height: 52)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: phaseKey)
    }

    private var phaseKey: Int {
        switch viewModel.phase {
        case .idle: return 0
        case .playingTone: return 1
        case .countIn: return 2
        case .singing: return 3
        case .revealing: return 4
        case .complete: return 5
        }
    }

    private func completionView(_ result: AudiationResult) -> some View {
        let meanCents = result.noteResults.map { $0.meanAbsCents }.reduce(0, +) / Double(max(1, result.noteResults.count))
        let hitRate = Double(result.passedCount) / Double(max(1, result.noteResults.count))
        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(result.scorePercent)%")
                    .font(.system(size: 52, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(scoreColor(result.scorePercent))
                Text("\(result.passedCount) of \(result.noteResults.count) notes in tune")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
            }

            RemediationCard(tip: RemediationEngine.tip(meanAbsCents: meanCents, hitRate: hitRate))

            HStack(spacing: 12) {
                Button("Try again") { viewModel.restart(); viewModel.start() }
                    .buttonStyle(TmSecondaryButtonStyle())
                Button("Done") {
                    XPManager.shared.award(xp: 10 + result.scorePercent / 10, badge: "audiation")
                    viewModel.restart(); dismiss()
                }
                .buttonStyle(TmPrimaryButtonStyle())
            }
        }
    }

    private func scoreColor(_ pct: Int) -> Color {
        pct >= 80 ? .tmGood : pct >= 50 ? Color(red: 0.9, green: 0.78, blue: 0.3) : .tmWarn
    }
}

// MARK: - Button styles

struct TmPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.tmAccentInk)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.tmAccent.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TmSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.tmInk)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.tmSurface.opacity(configuration.isPressed ? 0.6 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tmLine, lineWidth: 1))
    }
}
