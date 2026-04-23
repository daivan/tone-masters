import SwiftUI

struct PitchCharacterView: View {
    @ObservedObject var viewModel: PitchCharacterViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionStart = Date()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.06, green: 0.05, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                pitchLane
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                bottomControls
                    .padding(.bottom, 40)
                    .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            sessionStart = Date()
            RestReminderManager.shared.scheduleReminder()
        }
        .onDisappear {
            RestReminderManager.shared.cancelReminder()
            DailyLimitManager.shared.recordSession(seconds: Date().timeIntervalSince(sessionStart))
            viewModel.stop()
        }
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
            Text("CHARACTER")
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

    // MARK: - Pitch lane

    private var pitchLane: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let fraction = viewModel.characterFraction
            let orbY = h * (1.0 - fraction)
            let orbX = w / 2.0

            ZStack {
                // Faint horizontal lane lines (every semitone area)
                Canvas { ctx, size in
                    let lineCount = 13
                    for i in 0..<lineCount {
                        let y = size.height * CGFloat(i) / CGFloat(lineCount - 1)
                        var line = Path()
                        line.move(to: CGPoint(x: 0, y: y))
                        line.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(line, with: .color(Color.white.opacity(0.06)),
                                   style: StrokeStyle(lineWidth: 0.5, dash: [4, 6]))
                    }
                }

                if !viewModel.isActive {
                    VStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.tmDimmer)
                        Text("Sing to move the character")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(Color.tmDim)
                    }
                } else {
                    // Glowing orb
                    ZStack {
                        // Glow blur layer
                        Circle()
                            .fill(Color.tmAccent.opacity(0.35))
                            .frame(width: 60, height: 60)
                            .blur(radius: 14)
                            .position(x: orbX, y: orbY)

                        // Solid mint orb
                        Circle()
                            .fill(Color.tmAccent)
                            .frame(width: 44, height: 44)
                            .position(x: orbX, y: orbY)

                        // Note label to the right
                        if let note = viewModel.currentNote {
                            Text(note)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.tmAccent)
                                .position(x: orbX + 36, y: orbY)
                        }
                    }
                    .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: fraction)
                }
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
