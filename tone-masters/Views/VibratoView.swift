import SwiftUI

struct VibratoView: View {
    @ObservedObject var viewModel: VibratoViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                Spacer()
                ringDisplay
                Spacer()
                trailCanvas
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                targetZoneLabels
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .task { viewModel.start() }
        .onDisappear { viewModel.stop() }
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
            Text("VIBRATO ZONE")
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

    // MARK: - Ring display

    private var ringDisplay: some View {
        let hz = viewModel.vibratoHz
        let inZone = viewModel.isInZone
        let fraction = min(1.0, hz / 10.0)
        let arcColor: Color = inZone ? .tmGood : (hz > 0 ? Color(red: 0.9, green: 0.78, blue: 0.3) : Color.tmDimmer)

        return ZStack {
            // Background ring
            Circle()
                .stroke(Color.tmDimmer, lineWidth: 16)
                .frame(width: 200, height: 200)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .foregroundStyle(arcColor)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.15), value: fraction)

            // Center content
            VStack(spacing: 4) {
                Text(String(format: "%.1f Hz", hz))
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundStyle(Color.tmInk)
                    .monospacedDigit()
                Text(statusText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(statusColor)
                    .kerning(0.5)
            }
        }
    }

    private var statusText: String {
        let hz = viewModel.vibratoHz
        if !viewModel.isActive { return "Sing with vibrato" }
        if viewModel.isInZone  { return "In zone!" }
        if hz > 7.0            { return "Too fast" }
        if hz > 0              { return "Too slow" }
        return "Sing with vibrato"
    }

    private var statusColor: Color {
        if viewModel.isInZone { return .tmGood }
        if viewModel.vibratoHz > 7.0 { return .tmWarn }
        return Color.tmDim
    }

    // MARK: - Trail canvas

    private var trailCanvas: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            Canvas { ctx, size in
                let points = viewModel.trailPoints
                guard points.count >= 2 else { return }

                let now = Date()
                let windowDur: Double = 2.0
                let midiValues = points.map { $0.midi }
                let minMidi = (midiValues.min() ?? 60) - 1
                let maxMidi = (midiValues.max() ?? 72) + 1
                let midiRange = maxMidi - minMidi

                var path = Path()
                for (i, pt) in points.enumerated() {
                    let age = now.timeIntervalSince(pt.date)
                    let x = (1.0 - age / windowDur) * size.width
                    let y = (1.0 - (pt.midi - minMidi) / midiRange) * size.height
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                ctx.stroke(path, with: .color(Color.tmAccent.opacity(0.7)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 80)
            .background(Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.tmLine, lineWidth: 1))
        }
    }

    // MARK: - Target zone labels

    private var targetZoneLabels: some View {
        HStack {
            Text("Target: 5–7 Hz")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Color.tmGood).frame(width: 6, height: 6)
                Text("In zone")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
            }
        }
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        Group {
            if viewModel.isActive {
                Button("Stop") { viewModel.stop() }
                    .buttonStyle(TmSecondaryButtonStyle())
            } else {
                Button("Start") { viewModel.start() }
                    .buttonStyle(TmPrimaryButtonStyle())
            }
        }
    }
}
