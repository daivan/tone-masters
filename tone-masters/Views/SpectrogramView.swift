import SwiftUI

struct SpectrogramView: View {
    @ObservedObject var viewModel: SpectrogramViewModel
    @ObservedObject var audioEngine: AudioEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                Spacer()
                spectrumCanvas
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                infoStrip
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
            Text("SPECTROGRAM")
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

    // MARK: - Spectrum canvas

    private var spectrumCanvas: some View {
        let freqMin: Double = 80
        let freqMax: Double = 4000
        let logMin = log(freqMin)
        let logMax = log(freqMax)

        return TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            Canvas { ctx, size in
                let magnitudes = viewModel.magnitudes
                let plotHeight = size.height - 20  // Leave 20pt for x-axis labels

                guard !magnitudes.isEmpty else { return }

                // Draw frequency bars
                for bin in 2..<min(magnitudes.count, 94) {
                    let freq = viewModel.frequency(forBin: bin)
                    guard freq >= freqMin && freq <= freqMax else { continue }

                    let logFreq = log(freq)
                    let xFrac = (logFreq - logMin) / (logMax - logMin)
                    let x = xFrac * size.width

                    let barH = CGFloat(magnitudes[bin]) * plotHeight
                    let barW: CGFloat = max(2, size.width / 93.0)

                    // Color: gradient from accent (low) to orange (high)
                    let colorFrac = xFrac
                    let barColor = Color(
                        red: 0.369 + colorFrac * (0.878 - 0.369),
                        green: 0.796 + colorFrac * (0.420 - 0.796),
                        blue: 0.631 + colorFrac * (0.290 - 0.631)
                    )

                    let barRect = CGRect(x: x - barW / 2,
                                        y: plotHeight - barH,
                                        width: barW,
                                        height: max(1, barH))
                    ctx.fill(Path(roundedRect: barRect, cornerRadius: 1), with: .color(barColor))
                }

                // Reference frequency lines
                let refFreqs: [(Double, Bool)] = [
                    (220, false), (440, true), (880, false), (1760, false)
                ]
                for (refFreq, isMajor) in refFreqs {
                    guard refFreq >= freqMin && refFreq <= freqMax else { continue }
                    let logF = log(refFreq)
                    let xFrac = (logF - logMin) / (logMax - logMin)
                    let x = xFrac * size.width
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x, y: plotHeight))
                    ctx.stroke(line, with: .color(Color.tmAccent.opacity(isMajor ? 0.25 : 0.12)),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                }

                // Detected frequency + harmonics
                if let detFreq = audioEngine.detectedFrequency {
                    for harmonic in 1...4 {
                        let hFreq = detFreq * Double(harmonic)
                        guard hFreq >= freqMin && hFreq <= freqMax else { continue }
                        let logF = log(hFreq)
                        let xFrac = (logF - logMin) / (logMax - logMin)
                        let x = xFrac * size.width
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: 0))
                        line.addLine(to: CGPoint(x: x, y: plotHeight))
                        let opacity: Double = harmonic == 1 ? 0.9 : 0.4 / Double(harmonic)
                        ctx.stroke(line, with: .color(Color.tmAccent.opacity(opacity)),
                                   style: StrokeStyle(lineWidth: harmonic == 1 ? 1.5 : 1.0))
                    }
                }

                // X-axis labels
                let labelFreqs: [(Double, String)] = [
                    (100, "100"), (500, "500"), (1000, "1k"), (2000, "2k"), (4000, "4k")
                ]
                for (freq, label) in labelFreqs {
                    guard freq >= freqMin && freq <= freqMax else { continue }
                    let logF = log(freq)
                    let xFrac = (logF - logMin) / (logMax - logMin)
                    let x = xFrac * size.width
                    let text = Text(label)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.tmDimmer)
                    ctx.draw(text, at: CGPoint(x: x, y: plotHeight + 10))
                }
            }
            .frame(height: 200)
            .background(Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tmLine, lineWidth: 1))
        }
    }

    // MARK: - Info strip

    private var infoStrip: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.system(size: 12))
                .foregroundStyle(Color.tmDim)
            if let freq = audioEngine.detectedFrequency, let note = audioEngine.detectedNote {
                Text("F0: \(note) · \(Int(freq)) Hz")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.tmInk)
            } else {
                Text("—")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.tmDimmer)
            }
            Spacer()
            Text("80–4000 Hz")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDimmer)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.tmLine, lineWidth: 1))
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
