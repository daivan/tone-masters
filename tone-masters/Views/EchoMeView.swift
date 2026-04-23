import SwiftUI

struct EchoMeView: View {
    @ObservedObject var viewModel: EchoMeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart = Date()

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                Spacer()
                progressDots
                    .padding(.bottom, 20)
                phraseHeader
                phraseContour
                    .frame(height: 110)
                    .padding(.horizontal, 0)
                    .padding(.top, 14)
                Spacer()
                phaseArea
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
            Text("Echo Me")
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
            ForEach(0..<viewModel.phrases.count, id: \.self) { i in
                Circle()
                    .fill(dotColor(for: i))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentPhraseIndex)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        guard let current = viewModel.currentPhraseIndex else { return Color.tmDimmer }
        if index < current  { return .tmGood }
        if index == current { return .tmAccent }
        return Color.tmDimmer
    }

    // MARK: - Phrase header

    private var phraseHeader: some View {
        VStack(spacing: 4) {
            if let phrase = viewModel.currentPhrase {
                Text(phrase.name.uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .kerning(1.4)
                    .animation(.none, value: phrase.name)
            } else if case .complete = viewModel.phase {
                Text("COMPLETE")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .kerning(1.4)
            }
        }
    }

    // MARK: - Phrase contour canvas

    private var phraseContour: some View {
        Canvas { context, size in
            guard let phrase = viewModel.currentPhrase else { return }

            let notes     = phrase.notes
            let totalDur  = phrase.totalDuration
            let semitones = notes.map { $0.semitones }
            let minSt     = semitones.min() ?? 0
            let maxSt     = semitones.max() ?? 0
            let stRange   = max(1, maxSt - minSt)

            let blockH: CGFloat = 22
            let gap: CGFloat = 4
            let result = viewModel.resultForCurrentPhrase

            for i in notes.indices {
                let note   = notes[i]
                let xFrac  = phrase.noteStartTime(i) / totalDur
                let wFrac  = phrase.noteDuration(i)  / totalDur
                let yFrac  = 1.0 - Double(note.semitones - minSt) / Double(stRange)

                let x = CGFloat(xFrac) * size.width
                let w = max(8, CGFloat(wFrac) * size.width - gap)
                let y = CGFloat(yFrac) * (size.height - blockH)

                let rect  = CGRect(x: x, y: y, width: w, height: blockH)
                let color = blockColor(for: i, result: result)
                context.fill(Path(roundedRect: rect, cornerRadius: 7), with: .color(color))

                // Note label inside block
                if w > 28 {
                    let targetMidi = 60 + note.semitones  // just for label, center reference
                    let _ = targetMidi  // suppress warning — label not shown for now
                }
            }
        }
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tmLine, lineWidth: 1))
        .animation(.easeInOut(duration: 0.3), value: viewModel.resultForCurrentPhrase != nil)
    }

    private func blockColor(for index: Int, result: EchoPhraseResult?) -> Color {
        if let result {
            let r = result.noteResults[index]
            return r.passed ? Color.tmGood.opacity(0.75) : Color.tmWarn.opacity(0.65)
        }
        switch viewModel.phase {
        case .playingPhrase(_, let active):
            if index == active  { return Color.tmAccent }
            if index < active   { return Color.tmAccent.opacity(0.25) }
            return Color.tmSurface2
        case .singing:
            return Color.tmAccent.opacity(0.20)
        default:
            return Color.tmSurface2
        }
    }

    // MARK: - Phase area

    private var phaseArea: some View {
        VStack(spacing: 18) {
            switch viewModel.phase {
            case .idle:
                EmptyView()

            case .playingPhrase:
                listeningWave

            case .countIn(_, let count):
                Text("\(count)")
                    .font(.system(size: 72, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmAccent)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: count)

            case .singing:
                singingPulse

            case .revealing:
                if let result = viewModel.resultForCurrentPhrase {
                    let passed = result.passedCount == result.noteResults.count
                    Text(passed ? "Perfect echo!" : result.passedCount > 0 ? "Getting there!" : "Keep practicing!")
                        .font(.system(size: 26, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(passed ? Color.tmGood : Color.tmWarn)
                }

            case .complete:
                EmptyView()
            }

            if !viewModel.phaseLabel.isEmpty {
                Text(viewModel.phaseLabel)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .textCase(.uppercase)
                    .kerning(1.0)
            }
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
            case .complete:
                if let result = viewModel.gameResult {
                    completionView(result)
                }

            case .revealing:
                // Show per-note breakdown + next button
                VStack(spacing: 14) {
                    if let result = viewModel.resultForCurrentPhrase {
                        noteBreakdown(result)
                    }
                    Button("Next phrase") { viewModel.proceedFromReveal() }
                        .buttonStyle(TmPrimaryButtonStyle())
                }

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
        case .playingPhrase: return 1
        case .countIn: return 2
        case .singing: return 3
        case .revealing: return 4
        case .complete: return 5
        }
    }

    private func noteBreakdown(_ result: EchoPhraseResult) -> some View {
        HStack(spacing: 0) {
            ForEach(result.noteResults.indices, id: \.self) { i in
                let r = result.noteResults[i]
                VStack(spacing: 6) {
                    Image(systemName: r.passed ? "checkmark" : "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(r.passed ? Color.tmGood : Color.tmWarn)
                    Text("\(Int(r.hitRate * 100))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.tmLine, lineWidth: 1))
    }

    private func completionView(_ result: EchoGameResult) -> some View {
        let allNoteResults = result.phraseResults.flatMap { $0.noteResults }
        let meanHitRate = allNoteResults.map { $0.hitRate }.reduce(0, +) / Double(max(1, allNoteResults.count))
        let overallHitRate = Double(result.phraseResults.filter { $0.scorePercent >= 50 }.count) / Double(max(1, result.phraseResults.count))
        // Use meanHitRate as proxy for meanAbsCents (higher hitRate = lower cents error)
        let proxyCents = (1.0 - meanHitRate) * 80.0
        return VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(result.overallPercent)%")
                    .font(.system(size: 52, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(scoreColor(result.overallPercent))
                Text("\(result.phraseResults.filter { $0.scorePercent >= 50 }.count) of \(result.phraseResults.count) phrases matched")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
            }

            RemediationCard(tip: RemediationEngine.tip(meanAbsCents: proxyCents, hitRate: overallHitRate))

            VStack(spacing: 8) {
                ForEach(result.phraseResults.indices, id: \.self) { i in
                    let pr = result.phraseResults[i]
                    HStack {
                        Image(systemName: pr.scorePercent >= 50 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(pr.scorePercent >= 50 ? Color.tmGood : Color.tmWarn)
                            .font(.system(size: 14))
                        Text(pr.phrase.name)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(Color.tmInk)
                        Spacer()
                        Text("\(pr.scorePercent)%")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(pr.scorePercent >= 50 ? Color.tmGood : Color.tmWarn)
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
                    XPManager.shared.award(xp: 15 + result.overallPercent / 10, badge: "echo_me")
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
