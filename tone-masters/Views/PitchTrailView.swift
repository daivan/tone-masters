import SwiftUI

struct PitchTrailView: View {
    @ObservedObject var viewModel: PitchTrailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            noteStrip
            trailCanvas
            controls
        }
        .navigationTitle("Pitch Trail")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stopListening()
        }
    }

    // MARK: - Subviews

    private var noteStrip: some View {
        HStack(alignment: .center) {
            if let note = viewModel.currentNote {
                Text(note)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.08), value: note)
            } else {
                Text(viewModel.isListening ? "—" : "Tap Start to begin")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if viewModel.currentNote != nil {
                let cents = viewModel.currentCents
                let sign  = cents >= 0 ? "+" : ""
                Text("\(sign)\(Int(cents))¢")
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundStyle(centsColor(cents))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.1), value: Int(cents))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }

    private var trailCanvas: some View {
        ZStack {
            GeometryReader { geo in
                Canvas { context, size in
                    let plotRect = CGRect(
                        x: 40, y: 8,
                        width: size.width - 48,
                        height: size.height - 16
                    )
                    let samples = viewModel.samples
                    let now = Date.now
                    let window = viewModel.visibleWindowSeconds
                    let midiLow = viewModel.midiLow
                    let midiHigh = viewModel.midiHigh

                    drawGridLines(context, plotRect, midiLow, midiHigh)
                    drawYAxisLabels(context, plotRect, midiLow, midiHigh)
                    drawPitchTrail(context, plotRect, samples, now, window, midiLow, midiHigh)
                    drawNowLine(context, plotRect)
                }
            }
            .background(.ultraThinMaterial)

            // Blind mode overlay — covers the trail but lets mic keep running
            if viewModel.blindMode {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    VStack(spacing: 10) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.secondary)
                        Text("Blind mode — trust your ear")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .kerning(0.8)
                    }
                }
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
        .animation(.easeInOut(duration: 0.25), value: viewModel.blindMode)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                if viewModel.isListening {
                    viewModel.stopListening()
                } else {
                    viewModel.startListening()
                }
            } label: {
                Label(
                    viewModel.isListening ? "Stop" : "Start",
                    systemImage: viewModel.isListening ? "stop.fill" : "mic.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isListening ? .red : .cyan)
            .controlSize(.large)

            // Blind mode toggle — hide pitch trail so user relies on ear alone
            Button {
                viewModel.blindMode.toggle()
            } label: {
                Image(systemName: viewModel.blindMode ? "eye.slash.fill" : "eye")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.bordered)
            .tint(viewModel.blindMode ? .orange : .secondary)
            .controlSize(.large)

            if !viewModel.samples.isEmpty || !viewModel.isListening {
                Button("Clear") {
                    viewModel.clearTrail()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.samples.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func centsColor(_ cents: Double) -> Color {
        let magnitude = abs(cents)
        if magnitude <= 15 { return .green }
        if magnitude <= 30 { return .yellow }
        return .red
    }

    // MARK: - Canvas Drawing

    private func xForTime(_ timestamp: Date, now: Date, windowSeconds: Double, plotWidth: CGFloat) -> CGFloat {
        let age = now.timeIntervalSince(timestamp)
        let fraction = 1.0 - (age / windowSeconds)
        return plotWidth * CGFloat(max(0, min(1, fraction)))
    }

    private func yForMidi(_ midi: Double, midiLow: Double, midiHigh: Double, plotHeight: CGFloat) -> CGFloat {
        let clamped = max(midiLow, min(midiHigh, midi))
        let fraction = (clamped - midiLow) / (midiHigh - midiLow)
        return plotHeight * CGFloat(1.0 - fraction)
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
            let isC = midi % 12 == 0   // C notes: MIDI 0, 12, 24, 36, 48, 60, 72...
            // Label every note but only draw text for C notes and every other non-C
            // to avoid crowding. Always label C notes; label other notes every 2 semitones.
            let shouldLabel = isC || (midi % 2 == 0)
            guard shouldLabel else { continue }
            let y = yForMidi(Double(midi), midiLow: midiLow, midiHigh: midiHigh,
                             plotHeight: plotRect.height) + plotRect.minY
            let name = viewModel.noteName(for: midi)
            let label: Text = isC
                ? Text(name).font(.system(.caption, design: .monospaced).bold()).foregroundColor(.primary)
                : Text(name).font(.system(.caption2, design: .monospaced)).foregroundColor(.secondary.opacity(0.6))
            context.draw(label, at: CGPoint(x: plotRect.minX - 4, y: y), anchor: .trailing)
        }
    }

    private func drawPitchTrail(_ context: GraphicsContext, _ plotRect: CGRect,
                                _ samples: [PitchSample], _ now: Date,
                                _ windowSeconds: Double, _ midiLow: Double, _ midiHigh: Double) {
        guard !samples.isEmpty else { return }

        if samples.count == 1, let s = samples.first {
            let midi = viewModel.frequencyToMidi(s.frequency)
            let x = xForTime(s.timestamp, now: now, windowSeconds: windowSeconds,
                             plotWidth: plotRect.width) + plotRect.minX
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
            let midi = viewModel.frequencyToMidi(s.frequency)
            let x = xForTime(s.timestamp, now: now, windowSeconds: windowSeconds,
                             plotWidth: plotRect.width) + plotRect.minX
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

        context.stroke(
            path,
            with: .color(.cyan),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawNowLine(_ context: GraphicsContext, _ plotRect: CGRect) {
        var line = Path()
        line.move(to: CGPoint(x: plotRect.maxX, y: plotRect.minY))
        line.addLine(to: CGPoint(x: plotRect.maxX, y: plotRect.maxY))
        context.stroke(
            line,
            with: .color(.white.opacity(0.35)),
            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
        )
    }
}
