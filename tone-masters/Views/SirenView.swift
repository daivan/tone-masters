import SwiftUI

struct SirenView: View {
    @ObservedObject var viewModel: SirenViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart = Date()

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                infoStrip
                sirenCanvas
                registerLegend
                controls
            }
        }
        .navigationBarHidden(true)
        .onAppear  { sessionStart = Date(); RestReminderManager.shared.scheduleReminder() }
        .onDisappear {
            RestReminderManager.shared.cancelReminder()
            DailyLimitManager.shared.recordSession(seconds: Date().timeIntervalSince(sessionStart))
            viewModel.stop()
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button { viewModel.stop(); dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tmInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
            }
            Spacer()
            Text("Siren")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.2)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Info strip

    private var infoStrip: some View {
        HStack {
            // Register + note name
            VStack(alignment: .leading, spacing: 2) {
                if let reg = viewModel.currentRegister() {
                    HStack(spacing: 6) {
                        Circle().fill(reg.color).frame(width: 8, height: 8)
                        Text(reg.label)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(reg.color)
                    }
                    .animation(.easeInOut(duration: 0.2), value: reg.label)
                } else {
                    Text(viewModel.phase == .active ? "—" : "Glide across your range")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
            }

            Spacer()

            // Direction + guide note
            if viewModel.phase == .active {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.tmAccent)
                    Text(midiNoteName(Int(viewModel.guideMidi.rounded())))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
            } else if viewModel.phase == .complete {
                Text("Complete!")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.tmGood)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
    }

    // MARK: - Canvas

    private var sirenCanvas: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let midiLow  = viewModel.midiLow
                let midiHigh = viewModel.midiHigh
                let plotRect = CGRect(x: 36, y: 8, width: size.width - 44, height: size.height - 16)

                drawRegisterZones(context, plotRect, midiLow, midiHigh)
                drawGridLines(context, plotRect, midiLow, midiHigh)
                drawYAxisLabels(context, plotRect, midiLow, midiHigh)
                drawPitchTrail(context, plotRect, midiLow, midiHigh, size)
                drawGuideLine(context, plotRect, midiLow, midiHigh)
            }
        }
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.tmLine, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    // MARK: - Register legend

    private var registerLegend: some View {
        HStack(spacing: 20) {
            ForEach([VocalRegister.chest, .mix, .head], id: \.label) { reg in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(reg.color)
                        .frame(width: 18, height: 4)
                    Text(reg.label)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            switch viewModel.phase {
            case .idle:
                Button("Start") { viewModel.start() }
                    .buttonStyle(TmPrimaryButtonStyle())

            case .active:
                Button("Stop") { viewModel.stop() }
                    .buttonStyle(TmSecondaryButtonStyle())

            case .complete:
                Button("Try again") { viewModel.restart() }
                    .buttonStyle(TmSecondaryButtonStyle())
                Button("Done") {
                    XPManager.shared.award(xp: 10, badge: "siren")
                    viewModel.stop(); dismiss()
                }
                .buttonStyle(TmPrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Coordinate helpers

    private func yForMidi(_ midi: Double, midiLow: Double, midiHigh: Double, plotHeight: CGFloat) -> CGFloat {
        let fraction = (midi - midiLow) / (midiHigh - midiLow)
        return plotHeight * CGFloat(1.0 - fraction)
    }

    // MARK: - Canvas drawing

    private func drawRegisterZones(_ context: GraphicsContext, _ plotRect: CGRect,
                                   _ midiLow: Double, _ midiHigh: Double) {
        let chestTop = yForMidi(viewModel.chestCeiling, midiLow: midiLow, midiHigh: midiHigh,
                                plotHeight: plotRect.height) + plotRect.minY
        let headTop  = yForMidi(viewModel.headFloor, midiLow: midiLow, midiHigh: midiHigh,
                                plotHeight: plotRect.height) + plotRect.minY

        // Chest zone (bottom)
        let chestRect = CGRect(x: plotRect.minX, y: chestTop,
                               width: plotRect.width, height: plotRect.maxY - chestTop)
        context.fill(Path(chestRect), with: .color(VocalRegister.chest.color.opacity(0.07)))

        // Mix zone (middle)
        let mixRect = CGRect(x: plotRect.minX, y: headTop,
                             width: plotRect.width, height: chestTop - headTop)
        context.fill(Path(mixRect), with: .color(VocalRegister.mix.color.opacity(0.07)))

        // Head zone (top)
        let headRect = CGRect(x: plotRect.minX, y: plotRect.minY,
                              width: plotRect.width, height: headTop - plotRect.minY)
        context.fill(Path(headRect), with: .color(VocalRegister.head.color.opacity(0.07)))

        // Zone divider lines
        for y in [chestTop, headTop] {
            var line = Path()
            line.move(to: CGPoint(x: plotRect.minX, y: y))
            line.addLine(to: CGPoint(x: plotRect.maxX, y: y))
            context.stroke(line, with: .color(Color.white.opacity(0.10)),
                           style: StrokeStyle(lineWidth: 0.8, dash: [6, 4]))
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
            context.stroke(line,
                           with: .color(isC ? Color.white.opacity(0.15) : Color.white.opacity(0.04)),
                           style: StrokeStyle(lineWidth: isC ? 0.8 : 0.4, dash: isC ? [] : [3, 5]))
            midi += 1
        }
    }

    private func drawYAxisLabels(_ context: GraphicsContext, _ plotRect: CGRect,
                                 _ midiLow: Double, _ midiHigh: Double) {
        for midi in Int(midiLow)...Int(midiHigh) {
            let isC = midi % 12 == 0
            guard isC || midi % 2 == 0 else { continue }
            let y = yForMidi(Double(midi), midiLow: midiLow, midiHigh: midiHigh,
                             plotHeight: plotRect.height) + plotRect.minY
            let name = midiNoteName(midi)
            let label: Text = isC
                ? Text(name).font(.system(.caption, design: .monospaced).bold()).foregroundColor(Color.tmInk)
                : Text(name).font(.system(.caption2, design: .monospaced)).foregroundColor(Color.tmDim)
            context.draw(label, at: CGPoint(x: plotRect.minX - 4, y: y), anchor: .trailing)
        }
    }

    private func drawPitchTrail(_ context: GraphicsContext, _ plotRect: CGRect,
                                _ midiLow: Double, _ midiHigh: Double, _ size: CGSize) {
        guard viewModel.samples.count >= 2 else { return }

        let now      = Date.now
        let window   = viewModel.totalDuration   // show full session width
        let pxPerSec = plotRect.width / CGFloat(window)

        // Group consecutive samples by register and draw as colored segments
        var i = 0
        while i < viewModel.samples.count - 1 {
            let s1 = viewModel.samples[i]
            let s2 = viewModel.samples[i + 1]

            let gap = s2.timestamp.timeIntervalSince(s1.timestamp)
            if gap > 0.2 { i += 1; continue }   // silence gap

            let midi1 = viewModel.frequencyToMidi(s1.frequency)
            let midi2 = viewModel.frequencyToMidi(s2.frequency)
            let reg   = viewModel.register(forMidi: (midi1 + midi2) / 2)

            let age1  = now.timeIntervalSince(s1.timestamp)
            let age2  = now.timeIntervalSince(s2.timestamp)
            let x1 = plotRect.maxX - CGFloat(age1) * pxPerSec
            let x2 = plotRect.maxX - CGFloat(age2) * pxPerSec
            let y1 = yForMidi(midi1, midiLow: midiLow, midiHigh: midiHigh, plotHeight: plotRect.height) + plotRect.minY
            let y2 = yForMidi(midi2, midiLow: midiLow, midiHigh: midiHigh, plotHeight: plotRect.height) + plotRect.minY

            guard x1 >= plotRect.minX || x2 >= plotRect.minX else { i += 1; continue }

            var seg = Path()
            seg.move(to: CGPoint(x: x1, y: y1))
            seg.addLine(to: CGPoint(x: x2, y: y2))
            context.stroke(seg, with: .color(reg.color),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            i += 1
        }
    }

    private func drawGuideLine(_ context: GraphicsContext, _ plotRect: CGRect,
                               _ midiLow: Double, _ midiHigh: Double) {
        guard viewModel.phase == .active else { return }

        let y = yForMidi(viewModel.guideMidi, midiLow: midiLow, midiHigh: midiHigh,
                         plotHeight: plotRect.height) + plotRect.minY
        let reg = viewModel.register(forMidi: viewModel.guideMidi)

        // Glow band
        let glow = Path(CGRect(x: plotRect.minX, y: y - 8, width: plotRect.width, height: 16))
        context.fill(glow, with: .color(reg.color.opacity(0.12)))

        // Guide line
        var line = Path()
        line.move(to: CGPoint(x: plotRect.minX, y: y))
        line.addLine(to: CGPoint(x: plotRect.maxX, y: y))
        context.stroke(line, with: .color(reg.color.opacity(0.70)),
                       style: StrokeStyle(lineWidth: 1.5, dash: [8, 5]))

        // Arrow head on right edge (shows direction)
        let arrowX = plotRect.maxX - 12
        let dy: CGFloat = viewModel.isAscending ? 6 : -6
        var arrow = Path()
        arrow.move(to: CGPoint(x: arrowX,      y: y + dy))
        arrow.addLine(to: CGPoint(x: arrowX + 10, y: y))
        arrow.addLine(to: CGPoint(x: arrowX,      y: y - dy))
        context.stroke(arrow, with: .color(reg.color.opacity(0.80)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}
