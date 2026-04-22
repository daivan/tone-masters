import SwiftUI

struct FollowSongView: View {
    @ObservedObject var viewModel: FollowSongViewModel
    @State private var showScore = false

    var body: some View {
        VStack(spacing: 0) {
            infoStrip
            gameCanvas
            controls
        }
        .navigationTitle(viewModel.currentSong.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stopListening()
        }
        .sheet(isPresented: $showScore) {
            SongScoreView(viewModel: viewModel, isPresented: $showScore)
        }
    }

    // MARK: - Subviews

    private var infoStrip: some View {
        HStack(alignment: .center) {
            if viewModel.phase == .finished {
                Text("\(viewModel.overallScore)%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.overallScore >= 80 ? .green : (viewModel.overallScore >= 50 ? .yellow : .red))
            } else if let note = viewModel.currentNote {
                Text(note)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.08), value: note)
            } else {
                Text(viewModel.phase == .playing ? "—" : "Tap Start")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(viewModel.timeString(viewModel.elapsed) + " / " + viewModel.timeString(viewModel.currentSong.totalDuration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }

    private var gameCanvas: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let _ = viewModel.displayTick  // establish redraw dependency

                let elapsed  = viewModel.elapsed
                let now      = Date.now
                let song     = viewModel.currentSong
                let samples  = viewModel.samples
                let midiLow  = viewModel.midiLow
                let midiHigh = viewModel.midiHigh

                let plotRect = CGRect(x: 40, y: 8, width: size.width - 48, height: size.height - 16)
                let nowX     = plotRect.minX + plotRect.width * viewModel.nowLineFraction
                let pps      = plotRect.width / CGFloat(viewModel.totalWindowSeconds)

                drawGridLines(context, plotRect, midiLow, midiHigh)
                drawYAxisLabels(context, plotRect, midiLow, midiHigh)
                drawSongBlocks(context, plotRect, song, elapsed, nowX, pps, midiLow, midiHigh)
                drawPitchTrail(context, plotRect, samples, elapsed, now, nowX, pps, midiLow, midiHigh)
                drawNowLine(context, plotRect, nowX)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if viewModel.phase == .playing {
                    viewModel.stop()
                } else {
                    viewModel.start()
                }
            } label: {
                Label(
                    viewModel.phase == .playing ? "Stop" : "Start",
                    systemImage: viewModel.phase == .playing ? "stop.fill" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.phase == .playing ? .red : .green)
            .controlSize(.large)

            if viewModel.phase == .finished {
                Button("Restart") { viewModel.restart() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button("Results") { showScore = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Coordinate helpers

    private func xForSongTime(_ songTime: Double, elapsed: Double, nowX: CGFloat, pps: CGFloat) -> CGFloat {
        nowX + CGFloat(songTime - elapsed) * pps
    }

    private func yForMidi(_ midi: Double, midiLow: Double, midiHigh: Double, plotHeight: CGFloat) -> CGFloat {
        let clamped = max(midiLow, min(midiHigh, midi))
        let fraction = (clamped - midiLow) / (midiHigh - midiLow)
        return plotHeight * CGFloat(1.0 - fraction)
    }

    // MARK: - Canvas drawing

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
                with: .color(isC ? Color.primary.opacity(0.2) : Color.primary.opacity(0.06)),
                style: StrokeStyle(lineWidth: isC ? 1.0 : 0.5, dash: isC ? [] : [4, 4])
            )
            midi += 1
        }
    }

    private func drawYAxisLabels(_ context: GraphicsContext, _ plotRect: CGRect,
                                 _ midiLow: Double, _ midiHigh: Double) {
        let low = Int(midiLow)
        let high = Int(midiHigh)
        for midi in low...high {
            let isC = midi % 12 == 0
            guard isC || (midi % 2 == 0) else { continue }
            let y = yForMidi(Double(midi), midiLow: midiLow, midiHigh: midiHigh,
                             plotHeight: plotRect.height) + plotRect.minY
            let name = viewModel.noteName(for: midi)
            let label: Text = isC
                ? Text(name).font(.system(.caption, design: .monospaced).bold()).foregroundColor(.primary)
                : Text(name).font(.system(.caption2, design: .monospaced)).foregroundColor(.secondary.opacity(0.6))
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

            // Skip blocks entirely off-screen
            guard x2 > plotRect.minX && x1 < plotRect.maxX else { continue }

            let centerY = yForMidi(Double(viewModel.transposedMidi(for: note)), midiLow: midiLow, midiHigh: midiHigh,
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
                fillColor = hitting ? .green : .orange
                opacity   = hitting ? 0.90   : 0.65
            } else if isPassed {
                let rate = viewModel.hitRate(for: note)
                fillColor = rate >= 0.5 ? .green : .red
                opacity   = 0.35
            } else {
                fillColor = .yellow
                opacity   = 0.55
            }

            let roundedRect = Path(roundedRect: blockRect, cornerRadius: 4)
            context.fill(roundedRect, with: .color(fillColor.opacity(opacity)))

            if isActive {
                context.stroke(roundedRect, with: .color(.white.opacity(0.6)),
                               style: StrokeStyle(lineWidth: 1.0))
            }
        }
    }

    private func drawPitchTrail(_ context: GraphicsContext, _ plotRect: CGRect,
                                _ samples: [PitchSample], _ elapsed: Double, _ now: Date,
                                _ nowX: CGFloat, _ pps: CGFloat,
                                _ midiLow: Double, _ midiHigh: Double) {
        guard !samples.isEmpty else { return }

        if samples.count == 1, let s = samples.first {
            let sampleSongTime = elapsed + s.timestamp.timeIntervalSince(now)
            let x = xForSongTime(sampleSongTime, elapsed: elapsed, nowX: nowX, pps: pps)
            let midi = viewModel.frequencyToMidi(s.frequency)
            let y = yForMidi(midi, midiLow: midiLow, midiHigh: midiHigh,
                             plotHeight: plotRect.height) + plotRect.minY
            let dot = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
            context.fill(dot, with: .color(.cyan))
            return
        }

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

        context.stroke(path, with: .color(.cyan),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }

    private func drawNowLine(_ context: GraphicsContext, _ plotRect: CGRect, _ nowX: CGFloat) {
        let band = Path(CGRect(x: nowX - 2, y: plotRect.minY, width: 4, height: plotRect.height))
        context.fill(band, with: .color(.white.opacity(0.05)))

        var line = Path()
        line.move(to: CGPoint(x: nowX, y: plotRect.minY))
        line.addLine(to: CGPoint(x: nowX, y: plotRect.maxY))
        context.stroke(line, with: .color(.white.opacity(0.45)),
                       style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
    }
}
