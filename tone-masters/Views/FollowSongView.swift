import SwiftUI

struct FollowSongView: View {
    @ObservedObject var viewModel: FollowSongViewModel
    @State private var showScore = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                songInfoHeader
                gameCanvas
                scoreBar
                transportControls
            }
        }
        .navigationBarHidden(true)
        .onDisappear { viewModel.stopListening() }
        .sheet(isPresented: $showScore) {
            SongScoreView(viewModel: viewModel, isPresented: $showScore)
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tmInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
            }
            Spacer()
            Text("Follow the song")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.2)
            Spacer()
            // Status dot + note label + cents
            HStack(spacing: 6) {
                Circle()
                    .fill(isHittingCurrentNote ? Color.tmGood : Color.tmAccent)
                    .frame(width: 8, height: 8)
                    .shadow(color: isHittingCurrentNote ? Color.tmGood.opacity(0.8) : .clear, radius: 4)
                Text(viewModel.currentNote ?? "—")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.tmInk)
                    .frame(minWidth: 30, alignment: .leading)
                if let cents = viewModel.centsFromTarget {
                    let sign = cents >= 0 ? "+" : ""
                    Text("\(sign)\(Int(cents))¢")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(centsColor(cents))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.1), value: Int(cents))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Song info header

    private var songInfoHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Folk · easy")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .textCase(.uppercase)
                    .kerning(1.0)
                Text(viewModel.currentSong.title)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                statLabel(label: "BPM", value: String(format: "%.0f", viewModel.currentSong.bpm))
                statLabel(label: "Range",
                          value: "\(midiNoteName(viewModel.currentSong.lowestMidi + viewModel.transpositionOffset))–\(midiNoteName(viewModel.currentSong.highestMidi + viewModel.transpositionOffset))")
                Text(viewModel.timeString(viewModel.elapsed) + " / " + viewModel.timeString(viewModel.currentSong.totalDuration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private func statLabel(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.tmDimmer)
                .kerning(0.8)
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Color.tmInk)
        }
    }

    // MARK: - Game canvas

    private var gameCanvas: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let _ = viewModel.displayTick  // redraw dependency

                let elapsed  = viewModel.elapsed
                let now      = Date.now
                let song     = viewModel.currentSong
                let samples  = viewModel.samples
                let midiLow  = viewModel.midiLow
                let midiHigh = viewModel.midiHigh

                let plotRect = CGRect(x: 34, y: 8, width: size.width - 42, height: size.height - 16)
                let nowX     = plotRect.minX + plotRect.width * viewModel.nowLineFraction
                let pps      = plotRect.width / CGFloat(viewModel.totalWindowSeconds)

                drawBlackKeyShading(context, plotRect, midiLow, midiHigh)
                drawGridLines(context, plotRect, midiLow, midiHigh)
                drawYAxisLabels(context, plotRect, midiLow, midiHigh)
                drawSongBlocks(context, plotRect, song, elapsed, nowX, pps, midiLow, midiHigh)
                drawPitchTrail(context, plotRect, samples, elapsed, now, nowX, pps, midiLow, midiHigh)
                drawVoiceDot(context, plotRect, nowX, midiLow, midiHigh)
                drawNowLine(context, plotRect, nowX)
            }
        }
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tmLine, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    // MARK: - Score bar

    private var scoreBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("ACCURACY")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .kerning(1.0)
                Spacer()
                if viewModel.phase == .finished {
                    HStack(spacing: 0) {
                        Text("\(viewModel.overallScore)")
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .italic()
                            .foregroundStyle(scoreColor)
                        Text(" / 100")
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(Color.tmDim)
                    }
                } else {
                    Text(viewModel.phase == .playing ? "Singing…" : "Tap ▶ to start")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.tmSurface2)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.tmGood)
                        .frame(width: geo.size.width * CGFloat(liveScoreFraction))
                        .animation(.linear(duration: 0.12), value: liveScoreFraction)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Transport controls

    private var transportControls: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Restart
                TransportButton {
                    Image(systemName: "backward.end.fill").font(.system(size: 15))
                        .foregroundStyle(Color.tmInk)
                } action: { viewModel.restart() }

                // Play / Stop — large accent button
                Button {
                    if viewModel.phase == .playing { viewModel.stop() }
                    else if viewModel.phase == .finished { viewModel.restart() }
                    else { viewModel.start() }
                } label: {
                    Image(systemName: viewModel.phase == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.tmAccentInk)
                        .frame(width: 72, height: 72)
                        .background(Color.tmAccent)
                        .clipShape(Circle())
                        .shadow(color: Color.tmAccent.opacity(0.35), radius: 12, y: 4)
                }

                // Results (visible when finished) or forward skip
                if viewModel.phase == .finished {
                    TransportButton {
                        Image(systemName: "list.star").font(.system(size: 15))
                            .foregroundStyle(Color.tmInk)
                    } action: { showScore = true }
                } else {
                    TransportButton {
                        Image(systemName: "forward.end.fill").font(.system(size: 15))
                            .foregroundStyle(Color.tmInk.opacity(0.35))
                    } action: { }
                    .disabled(true)
                }
            }
            .padding(.top, 14)

            // Mode tags
            HStack(spacing: 22) {
                modeTag("Melody", active: true)
                modeTag("+ Harmony", active: false)
                modeTag("Lyrics", active: false)
            }
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }

    private func modeTag(_ label: String, active: Bool) -> some View {
        Text(label.uppercased())
            .font(.system(size: 11, design: .monospaced))
            .kerning(0.8)
            .foregroundStyle(active ? Color.tmInk : Color.tmDim)
            .padding(.bottom, 3)
            .overlay(alignment: .bottom) {
                if active {
                    Rectangle().fill(Color.tmAccent).frame(height: 1)
                }
            }
    }

    // MARK: - Helpers

    private var isHittingCurrentNote: Bool {
        guard let note = viewModel.activeNote else { return false }
        return viewModel.isCurrentlyHitting(targetMidi: viewModel.transposedMidi(for: note))
    }

    private var liveScoreFraction: Double {
        if viewModel.phase == .finished { return Double(viewModel.overallScore) / 100.0 }
        guard let note = viewModel.activeNote else { return 0 }
        return viewModel.hitRate(for: note)
    }

    private var scoreColor: Color {
        viewModel.overallScore >= 80 ? .tmGood :
        viewModel.overallScore >= 50 ? Color(red: 0.9, green: 0.78, blue: 0.3) : .tmWarn
    }

    private func centsColor(_ cents: Double) -> Color {
        let magnitude = abs(cents)
        if magnitude <= 15 { return .tmGood }
        if magnitude <= 30 { return Color(red: 0.9, green: 0.78, blue: 0.3) }
        return .tmWarn
    }

    // MARK: - Coordinate helpers

    private func xForSongTime(_ songTime: Double, elapsed: Double, nowX: CGFloat, pps: CGFloat) -> CGFloat {
        nowX + CGFloat(songTime - elapsed) * pps
    }

    private func yForMidi(_ midi: Double, midiLow: Double, midiHigh: Double, plotHeight: CGFloat) -> CGFloat {
        let clamped  = max(midiLow, min(midiHigh, midi))
        let fraction = (clamped - midiLow) / (midiHigh - midiLow)
        return plotHeight * CGFloat(1.0 - fraction)
    }

    // MARK: - Canvas drawing

    private func drawBlackKeyShading(_ context: GraphicsContext, _ plotRect: CGRect,
                                     _ midiLow: Double, _ midiHigh: Double) {
        let blackKeys: Set<Int> = [1, 3, 6, 8, 10]
        var midi = midiLow
        let rowH = plotRect.height / CGFloat(midiHigh - midiLow)
        while midi <= midiHigh {
            if blackKeys.contains(Int(midi) % 12) {
                let y = yForMidi(midi + 1, midiLow: midiLow, midiHigh: midiHigh,
                                 plotHeight: plotRect.height) + plotRect.minY
                let shade = Path(CGRect(x: plotRect.minX, y: y, width: plotRect.width, height: rowH))
                context.fill(shade, with: .color(Color.white.opacity(0.025)))
            }
            midi += 1
        }
    }

    private func drawGridLines(_ context: GraphicsContext, _ plotRect: CGRect,
                               _ midiLow: Double, _ midiHigh: Double) {
        var midi = midiLow
        while midi <= midiHigh {
            let y = yForMidi(midi, midiLow: midiLow, midiHigh: midiHigh,
                             plotHeight: plotRect.height) + plotRect.minY
            var line = Path()
            line.move(to: CGPoint(x: plotRect.minX, y: y))
            line.addLine(to: CGPoint(x: plotRect.maxX, y: y))
            let isC = Int(midi) % 12 == 0
            context.stroke(
                line,
                with: .color(isC ? Color.white.opacity(0.18) : Color.white.opacity(0.05)),
                style: StrokeStyle(lineWidth: isC ? 0.8 : 0.5, dash: isC ? [] : [3, 5])
            )
            midi += 1
        }
    }

    private func drawYAxisLabels(_ context: GraphicsContext, _ plotRect: CGRect,
                                 _ midiLow: Double, _ midiHigh: Double) {
        let low  = Int(midiLow)
        let high = Int(midiHigh)
        for midi in low...high {
            let isC = midi % 12 == 0
            guard isC || midi % 2 == 0 else { continue }
            let y    = yForMidi(Double(midi), midiLow: midiLow, midiHigh: midiHigh,
                                plotHeight: plotRect.height) + plotRect.minY
            let name = midiNoteName(midi)
            let label: Text = isC
                ? Text(name).font(.system(.caption, design: .monospaced).bold()).foregroundColor(Color.tmInk)
                : Text(name).font(.system(.caption2, design: .monospaced)).foregroundColor(Color.tmDim)
            context.draw(label, at: CGPoint(x: plotRect.minX - 4, y: y), anchor: .trailing)
        }
    }

    private func drawSongBlocks(_ context: GraphicsContext, _ plotRect: CGRect,
                                _ song: Song, _ elapsed: Double,
                                _ nowX: CGFloat, _ pps: CGFloat,
                                _ midiLow: Double, _ midiHigh: Double) {
        let semitoneHeight = plotRect.height / CGFloat(midiHigh - midiLow)
        let halfH = semitoneHeight * 1.5

        for note in song.notes {
            let startTime = note.startTime(bpm: song.bpm)
            let endTime   = note.endTime(bpm: song.bpm)

            let x1 = xForSongTime(startTime, elapsed: elapsed, nowX: nowX, pps: pps)
            let x2 = xForSongTime(endTime,   elapsed: elapsed, nowX: nowX, pps: pps)
            guard x2 > plotRect.minX && x1 < plotRect.maxX else { continue }

            let centerY = yForMidi(Double(viewModel.transposedMidi(for: note)),
                                   midiLow: midiLow, midiHigh: midiHigh,
                                   plotHeight: plotRect.height) + plotRect.minY
            let blockRect = CGRect(
                x: max(x1, plotRect.minX),
                y: centerY - halfH,
                width: min(x2, plotRect.maxX) - max(x1, plotRect.minX),
                height: halfH * 2
            )

            let isActive = startTime <= elapsed && elapsed < endTime
            let isPassed = endTime < elapsed

            let fillColor: Color
            let opacity: Double

            if isActive {
                let hitting = viewModel.isCurrentlyHitting(targetMidi: viewModel.transposedMidi(for: note))
                fillColor = hitting ? .tmGood : .tmAccent
                opacity   = hitting ? 0.90    : 0.65
            } else if isPassed {
                let rate = viewModel.hitRate(for: note)
                fillColor = rate >= 0.5 ? .tmGood : .tmWarn
                opacity   = 0.40
            } else {
                fillColor = .tmAccent
                opacity   = 0.50
            }

            let roundedRect = Path(roundedRect: blockRect, cornerRadius: 5)
            context.fill(roundedRect, with: .color(fillColor.opacity(opacity)))

            if isActive {
                context.stroke(roundedRect, with: .color(Color.white.opacity(0.5)),
                               style: StrokeStyle(lineWidth: 1.0))
            }
        }
    }

    private func drawPitchTrail(_ context: GraphicsContext, _ plotRect: CGRect,
                                _ samples: [PitchSample], _ elapsed: Double, _ now: Date,
                                _ nowX: CGFloat, _ pps: CGFloat,
                                _ midiLow: Double, _ midiHigh: Double) {
        guard samples.count >= 2 else { return }

        var path = Path()
        var inSegment = false

        for i in 0..<samples.count {
            let s = samples[i]
            let sampleSongTime = elapsed + s.timestamp.timeIntervalSince(now)
            let x = xForSongTime(sampleSongTime, elapsed: elapsed, nowX: nowX, pps: pps)
            let midi = viewModel.frequencyToMidi(s.frequency)
            let y = yForMidi(midi, midiLow: midiLow, midiHigh: midiHigh,
                             plotHeight: plotRect.height) + plotRect.minY
            let point = CGPoint(x: x, y: y)

            if !inSegment {
                path.move(to: point)
                inSegment = true
            } else {
                let gap = s.timestamp.timeIntervalSince(samples[i - 1].timestamp)
                if gap > viewModel.silenceGapSeconds {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
        }

        context.stroke(path, with: .color(Color.tmAccent.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    private func drawVoiceDot(_ context: GraphicsContext, _ plotRect: CGRect,
                              _ nowX: CGFloat, _ midiLow: Double, _ midiHigh: Double) {
        guard let freq = viewModel.currentFrequency else { return }
        let midi = viewModel.frequencyToMidi(freq)
        let y = yForMidi(midi, midiLow: midiLow, midiHigh: midiHigh,
                         plotHeight: plotRect.height) + plotRect.minY
        let hitting = isHittingCurrentNote
        let dotColor: Color = hitting ? .tmGood : .tmAccent

        // Outer glow
        let glow = Path(ellipseIn: CGRect(x: nowX - 10, y: y - 10, width: 20, height: 20))
        context.fill(glow, with: .color(dotColor.opacity(0.25)))

        // Inner solid dot
        let dot = Path(ellipseIn: CGRect(x: nowX - 5, y: y - 5, width: 10, height: 10))
        context.fill(dot, with: .color(dotColor))
    }

    private func drawNowLine(_ context: GraphicsContext, _ plotRect: CGRect, _ nowX: CGFloat) {
        var line = Path()
        line.move(to: CGPoint(x: nowX, y: plotRect.minY))
        line.addLine(to: CGPoint(x: nowX, y: plotRect.maxY))
        context.stroke(line, with: .color(Color.tmInk.opacity(0.40)),
                       style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
    }
}

// MARK: - Transport button

struct TransportButton<Label: View>: View {
    let label: () -> Label
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label()
                .frame(width: 48, height: 48)
                .background(Color.tmSurface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
