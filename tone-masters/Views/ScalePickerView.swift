import SwiftUI

struct ScalePickerView: View {
    @ObservedObject var exerciseViewModel: ExerciseViewModel
    @ObservedObject var findRangeViewModel: FindYourRangeViewModel
    @ObservedObject var pitchTrailViewModel: PitchTrailViewModel
    @ObservedObject var followSongViewModel: FollowSongViewModel
    @ObservedObject var voiceSettings: VoiceSettings
    @ObservedObject var audioEngine: AudioEngine

    @State private var navigateToExercise    = false
    @State private var navigateToFindRange   = false
    @State private var navigateToMicTest     = false
    @State private var navigateToPitchTrail  = false
    @State private var navigateToFollowSong  = false
    @State private var navigateToSettings    = false

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topMeta
                    wordmark
                    heroCard
                    sectionHeader("Your range")
                    rangeStrip
                    sectionHeader("Today", hint: "3 exercises")
                    practiceQueue
                    sectionHeader("Library")
                    libraryGrid
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        // Destinations
        .navigationDestination(isPresented: $navigateToExercise) {
            ExerciseView(viewModel: exerciseViewModel)
        }
        .navigationDestination(isPresented: $navigateToFindRange) {
            FindYourRangeView(viewModel: findRangeViewModel)
        }
        .navigationDestination(isPresented: $navigateToMicTest) {
            MicTestView(audioEngine: audioEngine)
        }
        .navigationDestination(isPresented: $navigateToPitchTrail) {
            PitchTrailView(viewModel: pitchTrailViewModel)
        }
        .navigationDestination(isPresented: $navigateToFollowSong) {
            SongPickerView(viewModel: followSongViewModel)
        }
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingsView(settings: voiceSettings)
        }
    }

    // MARK: - Top meta row

    private var topMeta: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.tmSurface)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
                    Text("T")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .foregroundStyle(Color.tmInk)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Good evening")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                        .textCase(.uppercase)
                        .kerning(1.0)
                    Text("Singer")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.tmInk)
                }
            }
            Spacer()
            Button { navigateToSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.tmInk)
                    .frame(width: 36, height: 36)
                    .background(Color.tmSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.tmLine, lineWidth: 1))
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tone *Master*")
                .font(.system(size: 52, weight: .light, design: .serif))
                .foregroundStyle(Color.tmInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 6) {
                Circle().fill(Color.tmAccent).frame(width: 7, height: 7)
                Text("Practice makes permanent")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .textCase(.uppercase)
                    .kerning(0.8)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    // MARK: - Hero card

    private var heroCard: some View {
        Button { navigateToFindRange = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S WARM-UP")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.tmDim)
                            .kerning(1.2)
                        Text("Find your range")
                            .font(.system(size: 26, weight: .regular, design: .serif))
                            .foregroundStyle(Color.tmInk)
                        Text("Hum softly, slide up and down.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.tmDim)
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(Color.tmAccent).frame(width: 44, height: 44)
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.tmAccentInk)
                    }
                }

                LiveBarsView(color: .tmAccent, dimColor: .tmDimmer, count: 32, height: 60)
                    .frame(height: 60)
                    .padding(.top, 14)

                HStack {
                    Text(midiNoteName(voiceSettings.centerMidi - 12))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                    Spacer()
                    Text("LIVE · MIC")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                        .kerning(1.0)
                    Spacer()
                    Text(midiNoteName(voiceSettings.centerMidi + 12))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                }
                .padding(.top, 10)
            }
            .padding(18)
            .background(Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.tmLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Range strip

    private var rangeStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(voiceTypeName(voiceSettings.centerMidi)) · \(midiNoteName(voiceSettings.centerMidi - 12)) – \(midiNoteName(voiceSettings.centerMidi + 12))")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Color.tmInk)
                Spacer()
                Text("±12 semitones")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
            }

            RangeStripBars(centerMidi: voiceSettings.centerMidi)
        }
        .padding(16)
        .background(Color.tmSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.tmLine, lineWidth: 1))
    }

    // MARK: - Practice queue

    private var practiceQueue: some View {
        VStack(spacing: 10) {
            PracticeRow(
                index: "01",
                title: "Pitch Trail",
                kind: "Free sing",
                duration: "Open",
                highlight: false,
                viz: { AnyView(LiveBarsView(color: .tmAccent, dimColor: .tmDimmer, count: 14, height: 30).frame(height: 30)) }
            ) { navigateToPitchTrail = true }

            PracticeRow(
                index: "02",
                title: "Twinkle, Twinkle",
                kind: "Follow the song",
                duration: "0:24",
                highlight: true,
                viz: { AnyView(ScaleLaneMini()) }
            ) { navigateToFollowSong = true }

            if let scale = ScaleLibrary.all.first {
                PracticeRow(
                    index: "03",
                    title: scale.name,
                    kind: "Scale drill",
                    duration: "\(scale.notes.count) notes",
                    highlight: false,
                    viz: { AnyView(ScaleStairsMini(count: min(scale.notes.count, 8))) }
                ) {
                    exerciseViewModel.selectedScale = scale
                    navigateToExercise = true
                }
            }
        }
    }

    // MARK: - Library grid

    private var libraryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            LibraryTile(caption: "Scales", count: ScaleLibrary.all.count, dotColor: .tmAccent) {
                if let scale = ScaleLibrary.all.first {
                    exerciseViewModel.selectedScale = scale
                    navigateToExercise = true
                }
            }
            LibraryTile(caption: "Songs", count: SongLibrary.all.count, dotColor: .tmGood) {
                navigateToFollowSong = true
            }
            LibraryTile(caption: "Intervals", count: nil, dotColor: Color(red: 0.55, green: 0.50, blue: 0.85)) {
                navigateToExercise = true
            }
            LibraryTile(caption: "Mic test", count: nil, dotColor: .tmDim) {
                navigateToMicTest = true
            }
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ label: String, hint: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.4)
            Spacer()
            if let hint {
                Text(hint)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.tmDimmer)
            }
        }
        .padding(.top, 26)
        .padding(.bottom, 10)
    }
}

// MARK: - Animated live bars

struct LiveBarsView: View {
    let color: Color
    let dimColor: Color
    let count: Int
    let height: CGFloat

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let barW: CGFloat = 3
                let gap: CGFloat  = 3
                let total = CGFloat(count) * (barW + gap) - gap
                let startX = (size.width - total) / 2

                for i in 0..<count {
                    let phase = Double(i) * 0.35
                    let env = (0.35 + 0.65 * abs(sin(t * 2.2 + phase)))
                            * (0.5 + 0.5 * sin(t * 0.9 + Double(i) * 0.17))
                    let h = max(2.0, env * size.height)
                    let x = startX + CGFloat(i) * (barW + gap)
                    let bar = Path(CGRect(x: x, y: size.height - h, width: barW, height: h))
                    ctx.fill(bar, with: .color(i % 5 == 0 ? color : dimColor))
                }
            }
        }
    }
}

// MARK: - Range strip bars

struct RangeStripBars: View {
    let centerMidi: Int

    private var notes: [Int] { Array((centerMidi - 12)...(centerMidi + 12)) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(notes, id: \.self) { midi in
                let isC = midi % 12 == 0
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isC ? Color.tmAccent : Color.tmAccent.opacity(0.55))
                        .frame(width: 5, height: isC ? 36 : 22)
                    if isC {
                        Text(midiNoteName(midi))
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(Color.tmInk)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Practice row

struct PracticeRow: View {
    let index: String
    let title: String
    let kind: String
    let duration: String
    let highlight: Bool
    let viz: () -> AnyView
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Text(index)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(highlight ? Color.tmAccentInk : Color.tmInk)
                    .frame(width: 40, height: 40)
                    .background(highlight ? Color.tmAccent : Color.tmSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(title)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .foregroundStyle(Color.tmInk)
                        Spacer()
                        Text(duration)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.tmDim)
                    }
                    Text(kind.uppercased())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.tmDim)
                        .kerning(0.8)
                    viz().padding(.top, 6)
                }
            }
            .padding(14)
            .background(highlight ? Color.tmAccentDim : Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(highlight ? Color.clear : Color.tmLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Library tile

struct LibraryTile: View {
    let caption: String
    let count: Int?
    let dotColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Circle().fill(dotColor).frame(width: 10, height: 10)
                Spacer()
                HStack(alignment: .lastTextBaseline) {
                    Text(caption)
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Color.tmInk)
                    Spacer()
                    if let count {
                        Text("\(count)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.tmDim)
                    }
                }
            }
            .padding(14)
            .frame(minHeight: 86)
            .background(Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.tmLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini visualizations

struct ScaleLaneMini: View {
    private let dotPositions: [CGFloat] = [0.05, 0.15, 0.3, 0.4, 0.55, 0.65, 0.8, 0.9]
    private let pitchFracs: [CGFloat]   = [0.7, 0.7, 0.5, 0.5, 0.35, 0.35, 0.2, 0.2]

    var body: some View {
        Canvas { ctx, size in
            // grid lines
            for f in [0.25, 0.5, 0.75] as [CGFloat] {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: f * size.height))
                line.addLine(to: CGPoint(x: size.width, y: f * size.height))
                ctx.stroke(line, with: .color(Color.tmLine), style: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
            }
            // dots
            for (t, n) in zip(dotPositions, pitchFracs) {
                let x = t * size.width
                let y = n * size.height
                let dot = Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
                ctx.fill(dot, with: .color(Color.tmAccent))
            }
        }
        .frame(height: 32)
    }
}

struct ScaleStairsMini: View {
    let count: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.tmAccent.opacity(0.35 + Double(i) * 0.08))
                    .frame(width: 16, height: CGFloat(6 + i * 3))
            }
            Spacer()
            Text("C4→C5")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.tmDim)
        }
        .frame(height: 32)
    }
}
