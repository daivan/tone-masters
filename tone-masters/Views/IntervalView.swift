import SwiftUI

struct IntervalView: View {
    @ObservedObject var viewModel: IntervalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart = Date()

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                Spacer()
                progressDots
                    .padding(.bottom, 28)
                intervalDisplay
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
            Text("Interval Training")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.2)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.rounds.count, id: \.self) { i in
                Circle()
                    .fill(dotColor(for: i))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentRound)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        guard let current = viewModel.currentRound else { return Color.tmDimmer }
        if index < current  { return .tmGood }
        if index == current { return .tmAccent }
        return Color.tmDimmer
    }

    // MARK: - Interval display

    private var intervalDisplay: some View {
        VStack(spacing: 12) {
            if let interval = viewModel.currentInterval {
                // Leap diagram
                leapDiagram(semitones: interval.semitones)
                    .frame(height: 100)
                    .padding(.bottom, 4)

                // Interval name
                Text(interval.name)
                    .font(.system(size: 52, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmInk)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: interval.name)

                // Short name badge
                Text(interval.shortName)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.tmAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.tmAccent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Hint
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.tmDimmer)
                    Text(interval.hint)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.tmDimmer)
                }
                .padding(.top, 4)

                // Result badge
                if let result = viewModel.resultForCurrentRound {
                    resultBadge(result)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 8)
                }
            } else if case .complete = viewModel.phase {
                EmptyView()
            } else {
                // Idle placeholder
                leapDiagram(semitones: 7)
                    .frame(height: 100)
                    .opacity(0.3)
                    .padding(.bottom, 4)
                Text("Get Ready")
                    .font(.system(size: 52, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmDimmer)
            }
        }
        .animation(.spring(duration: 0.4), value: viewModel.resultForCurrentRound != nil)
    }

    private func resultBadge(_ result: IntervalRoundResult) -> some View {
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

    // MARK: - Leap diagram

    private func leapDiagram(semitones: Int) -> some View {
        Canvas { context, size in
            let fraction  = min(1.0, Double(semitones) / 12.0)
            let cx        = size.width / 2
            let bottomY   = size.height - 14
            let topY      = bottomY - CGFloat(fraction) * (size.height - 28)
            let radius: CGFloat = 12

            // Connecting line
            var line = Path()
            line.move(to: CGPoint(x: cx, y: bottomY - radius))
            line.addLine(to: CGPoint(x: cx, y: topY + radius))
            context.stroke(line, with: .color(Color.tmAccent.opacity(0.5)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))

            // Root circle (bottom)
            let rootRect = CGRect(x: cx - radius, y: bottomY - radius,
                                  width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rootRect), with: .color(Color.tmSurface2))
            context.stroke(Path(ellipseIn: rootRect), with: .color(Color.tmDim),
                           style: StrokeStyle(lineWidth: 1.5))

            // Target circle (top)
            let topRect = CGRect(x: cx - radius, y: topY - radius,
                                 width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: topRect), with: .color(Color.tmAccent))
        }
    }

    // MARK: - Phase indicator

    private var phaseIndicator: some View {
        VStack(spacing: 20) {
            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .playingRoot:
                listeningWave

            case .playingInterval:
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
                Text(passed ? "In tune!" : "Keep training!")
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(passed ? Color.tmGood : Color.tmWarn)

            case .complete:
                EmptyView()
            }

            // Phase label
            if showingLabel {
                Text(viewModel.phaseLabel)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .textCase(.uppercase)
                    .kerning(1.0)
            }
        }
    }

    private var showingLabel: Bool {
        switch viewModel.phase {
        case .countIn, .singing, .revealing: return false
        case .playingRoot, .playingInterval: return true
        default: return true
        }
    }

    private var listeningWave: some View {
        LiveBarsView(color: .tmAccent, dimColor: .tmDimmer, count: 20, height: 48)
            .frame(width: 180, height: 48)
    }

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
                Button("Next interval") { viewModel.proceedFromReveal() }
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
        case .playingRoot: return 1
        case .playingInterval: return 2
        case .countIn: return 3
        case .singing: return 4
        case .revealing: return 5
        case .complete: return 6
        }
    }

    private func completionView(_ result: IntervalGameResult) -> some View {
        let meanCents = result.rounds.map { $0.meanAbsCents }.reduce(0, +) / Double(max(1, result.rounds.count))
        let hitRate = Double(result.passedCount) / Double(max(1, result.rounds.count))
        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(result.scorePercent)%")
                    .font(.system(size: 52, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(scoreColor(result.scorePercent))
                Text("\(result.passedCount) of \(result.rounds.count) intervals in tune")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
            }

            RemediationCard(tip: RemediationEngine.tip(meanAbsCents: meanCents, hitRate: hitRate))

            // Per-round summary
            VStack(spacing: 8) {
                ForEach(result.rounds.indices, id: \.self) { i in
                    let r = result.rounds[i]
                    HStack {
                        Image(systemName: r.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(r.passed ? Color.tmGood : Color.tmWarn)
                            .font(.system(size: 14))
                        Text(r.interval.shortName)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.tmInk)
                            .frame(width: 32, alignment: .leading)
                        Text(r.interval.name)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color.tmDim)
                        Spacer()
                        Text("±\(Int(r.meanAbsCents))¢")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(r.passed ? Color.tmGood : Color.tmWarn)
                    }
                }
            }
            .padding(14)
            .background(Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.tmLine, lineWidth: 1))

            HStack(spacing: 12) {
                Button("Try again") { viewModel.restart(); viewModel.start() }
                    .buttonStyle(TmSecondaryButtonStyle())
                Button("Done") {
                    XPManager.shared.award(xp: 10 + result.scorePercent / 10, badge: "interval")
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
