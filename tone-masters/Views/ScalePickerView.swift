import SwiftUI

struct ScalePickerView: View {
    @ObservedObject var exerciseViewModel: ExerciseViewModel
    @ObservedObject var findRangeViewModel: FindYourRangeViewModel
    @ObservedObject var pitchTrailViewModel: PitchTrailViewModel
    @ObservedObject var followSongViewModel: FollowSongViewModel
    @ObservedObject var audiationViewModel: AudiationViewModel
    @ObservedObject var sirenViewModel: SirenViewModel
    @ObservedObject var intervalViewModel: IntervalViewModel
    @ObservedObject var echoMeViewModel: EchoMeViewModel
    @ObservedObject var pitchCharacterViewModel: PitchCharacterViewModel
    @ObservedObject var vibratoViewModel: VibratoViewModel
    @ObservedObject var hissChallengeViewModel: HissChallengeViewModel
    @ObservedObject var spectrogramViewModel: SpectrogramViewModel
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var voiceSettings: VoiceSettings
    @ObservedObject var audioEngine: AudioEngine

    @State private var navigateToExercise      = false
    @State private var navigateToFindRange     = false
    @State private var navigateToMicTest       = false
    @State private var navigateToPitchTrail    = false
    @State private var navigateToFollowSong    = false
    @State private var navigateToAudiation     = false
    @State private var navigateToSiren         = false
    @State private var navigateToInterval      = false
    @State private var navigateToEchoMe        = false
    @State private var navigateToSettings      = false
    @State private var navigateToCharacter     = false
    @State private var navigateToVibrato       = false
    @State private var navigateToHiss          = false
    @State private var navigateToSpectrogram   = false

    var body: some View {
        ZStack {
            Color.tmBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topMeta
                    wordmark
                    xpStrip
                    if DailyLimitManager.shared.isEnabled {
                        practiceTimeStrip
                    }
                    if !XPManager.shared.unlockedBadges.isEmpty {
                        badgeShelf
                    }
                    heroCard
                    sectionHeader("Your range")
                    rangeStrip
                    sectionHeader("Today", hint: "7 exercises")
                    practiceQueue
                    sectionHeader("Library")
                    libraryGrid
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            streakManager.recordPractice()
            XPManager.shared.checkStreakBadges(streak: streakManager.currentStreak)
        }
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
        .navigationDestination(isPresented: $navigateToAudiation) {
            AudiationView(viewModel: audiationViewModel)
        }
        .navigationDestination(isPresented: $navigateToSiren) {
            SirenView(viewModel: sirenViewModel)
        }
        .navigationDestination(isPresented: $navigateToInterval) {
            IntervalView(viewModel: intervalViewModel)
        }
        .navigationDestination(isPresented: $navigateToEchoMe) {
            EchoMeView(viewModel: echoMeViewModel)
        }
        .navigationDestination(isPresented: $navigateToSettings) {
            SettingsView(settings: voiceSettings)
        }
        .navigationDestination(isPresented: $navigateToCharacter) {
            PitchCharacterView(viewModel: pitchCharacterViewModel)
        }
        .navigationDestination(isPresented: $navigateToVibrato) {
            VibratoView(viewModel: vibratoViewModel)
        }
        .navigationDestination(isPresented: $navigateToHiss) {
            HissChallengeView(viewModel: hissChallengeViewModel)
        }
        .navigationDestination(isPresented: $navigateToSpectrogram) {
            SpectrogramView(viewModel: spectrogramViewModel, audioEngine: audioEngine)
        }
    }

    // MARK: - XP strip

    @ObservedObject private var xp = XPManager.shared

    private var xpStrip: some View {
        HStack(spacing: 10) {
            // Level pill
            HStack(spacing: 5) {
                Text("LVL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.tmDim)
                    .kerning(1.0)
                Text("\(xp.level)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.tmInk)
            }
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Color.tmSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.tmLine, lineWidth: 1))

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tmSurface)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tmAccent)
                        .frame(width: geo.size.width * CGFloat(xp.xpInCurrentLevel) / CGFloat(xp.xpToNextLevel))
                }
            }
            .frame(height: 6)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.tmLine, lineWidth: 0.5))

            // XP label
            Text("\(xp.totalXP) XP")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .monospacedDigit()
        }
        .padding(.bottom, 12)
    }

    // MARK: - Daily practice time strip

    @ObservedObject private var dailyLimit = DailyLimitManager.shared

    private var practiceTimeStrip: some View {
        let atLimit = dailyLimit.isAtLimit
        let nearLimit = dailyLimit.isNearLimit
        let barColor: Color = atLimit ? .tmWarn : nearLimit ? Color(red: 0.9, green: 0.78, blue: 0.3) : .tmAccent

        return HStack(spacing: 10) {
            Image(systemName: atLimit ? "exclamationmark.triangle.fill" : "clock")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(barColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.tmSurface)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(dailyLimit.percentUsed))
                }
            }
            .frame(height: 6)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.tmLine, lineWidth: 0.5))

            Text(atLimit ? "Rest up" : "\(dailyLimit.todayMinutes)/\(dailyLimit.limitMinutes) min")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(atLimit ? barColor : Color.tmDim)
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.bottom, 10)
        .animation(.easeInOut(duration: 0.3), value: dailyLimit.percentUsed)
    }

    // MARK: - Badge shelf

    private var badgeShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Badges")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.tmDim)
                .textCase(.uppercase)
                .kerning(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(xp.unlockedBadges) { badge in
                        VStack(spacing: 6) {
                            Image(systemName: badge.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.tmAccent)
                                .frame(width: 44, height: 44)
                                .background(Color.tmAccent.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.tmAccent.opacity(0.25), lineWidth: 1))
                            Text(badge.name)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.tmDim)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                        }
                    }
                    // Locked badge placeholders
                    ForEach(xp.lockedBadges) { badge in
                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.tmDimmer)
                                .frame(width: 44, height: 44)
                                .background(Color.tmSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.tmLine, lineWidth: 1))
                            Text(badge.name)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.tmDimmer)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 4)
            }
        }
        .padding(.bottom, 4)
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
            HStack(spacing: 8) {
                // Streak badge
                if streakManager.currentStreak > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(streakManager.isStreakAlive ? Color(red: 1.0, green: 0.55, blue: 0.2) : Color.tmDimmer)
                        Text("\(streakManager.currentStreak)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(streakManager.isStreakAlive ? Color.tmInk : Color.tmDimmer)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 36)
                    .background(Color.tmSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(
                        streakManager.isStreakAlive ? Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.35) : Color.tmLine,
                        lineWidth: 1))
                }

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

            PracticeRow(
                index: "03",
                title: "Audiation",
                kind: "Hear · internalize · sing",
                duration: "5 notes",
                highlight: false,
                viz: { AnyView(AudiationMini()) }
            ) { navigateToAudiation = true }

            PracticeRow(
                index: "04",
                title: "Siren",
                kind: "Portamento · register zones",
                duration: "20 sec",
                highlight: false,
                viz: { AnyView(SirenMini()) }
            ) { navigateToSiren = true }

            PracticeRow(
                index: "05",
                title: "Interval Training",
                kind: "Leap accuracy · ear training",
                duration: "5 rounds",
                highlight: false,
                viz: { AnyView(IntervalMini()) }
            ) { navigateToInterval = true }

            PracticeRow(
                index: "06",
                title: "Echo Me",
                kind: "Listen · memorize · repeat",
                duration: "3 phrases",
                highlight: false,
                viz: { AnyView(EchoMeMini()) }
            ) { navigateToEchoMe = true }

            PracticeRow(
                index: "07",
                title: "Character",
                kind: "Pitch-controlled avatar",
                duration: "Open",
                highlight: false,
                viz: { AnyView(CharacterMini()) }
            ) { navigateToCharacter = true }

            PracticeRow(
                index: "08",
                title: "Vibrato Zone",
                kind: "Rate · consistency",
                duration: "Open",
                highlight: false,
                viz: { AnyView(VibratoMini()) }
            ) { navigateToVibrato = true }

            PracticeRow(
                index: "09",
                title: "Breath Hiss",
                kind: "Breath support · stamina",
                duration: "Open",
                highlight: false,
                viz: { AnyView(HissMini()) }
            ) { navigateToHiss = true }
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
            LibraryTile(caption: "Audiation", count: nil, dotColor: Color(red: 0.55, green: 0.50, blue: 0.85)) {
                navigateToAudiation = true
            }
            LibraryTile(caption: "Siren", count: nil, dotColor: Color(red: 0.55, green: 0.62, blue: 0.92)) {
                navigateToSiren = true
            }
            LibraryTile(caption: "Intervals", count: MusicalInterval.bank.count, dotColor: Color(red: 0.85, green: 0.62, blue: 0.40)) {
                navigateToInterval = true
            }
            LibraryTile(caption: "Echo Me", count: EchoPhrase.bank.count, dotColor: Color(red: 0.70, green: 0.50, blue: 0.90)) {
                navigateToEchoMe = true
            }
            LibraryTile(caption: "Character", count: nil, dotColor: Color(red: 0.45, green: 0.50, blue: 0.92)) {
                navigateToCharacter = true
            }
            LibraryTile(caption: "Vibrato", count: nil, dotColor: Color(red: 0.369, green: 0.796, blue: 0.631)) {
                navigateToVibrato = true
            }
            LibraryTile(caption: "Breath Hiss", count: nil, dotColor: Color(red: 0.878, green: 0.620, blue: 0.290)) {
                navigateToHiss = true
            }
            LibraryTile(caption: "Spectrogram", count: nil, dotColor: Color(red: 0.20, green: 0.80, blue: 0.90)) {
                navigateToSpectrogram = true
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

struct SirenMini: View {
    var body: some View {
        Canvas { ctx, size in
            // Draw a sine-wave-like glide curve representing portamento
            let colors: [Color] = [
                Color(red: 0.88, green: 0.55, blue: 0.28),  // chest (amber)
                Color.tmAccent,                              // mix (mint)
                Color(red: 0.55, green: 0.62, blue: 0.92),  // head (violet-blue)
            ]
            let segments = 60
            for i in 0..<(segments - 1) {
                let t1 = CGFloat(i)     / CGFloat(segments)
                let t2 = CGFloat(i + 1) / CGFloat(segments)
                let x1 = t1 * size.width
                let x2 = t2 * size.width
                // Ascending curve
                let y1 = size.height * (1.0 - t1)
                let y2 = size.height * (1.0 - t2)
                let colorIdx = min(2, Int(t1 * 3))
                var seg = Path()
                seg.move(to: CGPoint(x: x1, y: y1))
                seg.addLine(to: CGPoint(x: x2, y: y2))
                ctx.stroke(seg, with: .color(colors[colorIdx]),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
        }
        .frame(height: 32)
    }
}

struct AudiationMini: View {
    var body: some View {
        HStack(spacing: 10) {
            // Ear icon (listen)
            Image(systemName: "ear")
                .font(.system(size: 16))
                .foregroundStyle(Color.tmAccent)
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.tmDimmer)
            // Brain icon (internalize)
            Image(systemName: "brain")
                .font(.system(size: 16))
                .foregroundStyle(Color.tmAccent.opacity(0.6))
            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(Color.tmDimmer)
            // Mic icon (sing)
            Image(systemName: "mic.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.tmAccent.opacity(0.35))
            Spacer()
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

struct EchoMeMini: View {
    // Shows a phrase contour (blocks at different heights) + arrow suggesting "echo"
    private let blocks: [(x: CGFloat, y: CGFloat, w: CGFloat)] = [
        (0.02, 0.65, 0.14), (0.18, 0.40, 0.14), (0.34, 0.20, 0.14), (0.50, 0.40, 0.14),
    ]

    var body: some View {
        Canvas { ctx, size in
            let h: CGFloat = 10
            let purple = Color(red: 0.70, green: 0.50, blue: 0.90)

            // Original phrase blocks (solid)
            for b in blocks {
                let rect = CGRect(x: b.x * size.width, y: b.y * size.height,
                                  width: b.w * size.width, height: h)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(purple.opacity(0.7)))
            }

            // Arrow
            let arrowX = size.width * 0.68
            let midY = size.height * 0.42
            var arrow = Path()
            arrow.move(to: CGPoint(x: arrowX, y: midY))
            arrow.addLine(to: CGPoint(x: arrowX + 10, y: midY))
            arrow.move(to: CGPoint(x: arrowX + 6, y: midY - 4))
            arrow.addLine(to: CGPoint(x: arrowX + 10, y: midY))
            arrow.addLine(to: CGPoint(x: arrowX + 6, y: midY + 4))
            ctx.stroke(arrow, with: .color(Color.tmDimmer),
                       style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))

            // Echo blocks (dimmer, same shape, offset right)
            for b in blocks {
                let rect = CGRect(x: (b.x + 0.50) * size.width, y: b.y * size.height,
                                  width: b.w * size.width * 0.6, height: h)
                guard rect.maxX <= size.width else { continue }
                ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(purple.opacity(0.30)))
            }
        }
        .frame(height: 32)
    }
}

struct IntervalMini: View {
    // Static representation of a leap: two circles connected by a line
    private let intervals: [(semitones: Int, x: CGFloat)] = [
        (semitones: 5,  x: 0.12),
        (semitones: 7,  x: 0.35),
        (semitones: 12, x: 0.58),
        (semitones: 4,  x: 0.78),
    ]

    var body: some View {
        Canvas { ctx, size in
            let radius: CGFloat = 5
            let bottom = size.height - radius - 2

            for item in intervals {
                let cx = item.x * size.width
                let topY = bottom - CGFloat(item.semitones) / 12.0 * (size.height - 12)

                // Connecting line
                var line = Path()
                line.move(to: CGPoint(x: cx, y: bottom - radius))
                line.addLine(to: CGPoint(x: cx, y: topY + radius))
                ctx.stroke(line, with: .color(Color(red: 0.85, green: 0.62, blue: 0.40).opacity(0.4)),
                           style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                // Root dot (bottom)
                let rootRect = CGRect(x: cx - radius, y: bottom - radius, width: radius*2, height: radius*2)
                ctx.fill(Path(ellipseIn: rootRect), with: .color(Color.tmSurface2))
                ctx.stroke(Path(ellipseIn: rootRect), with: .color(Color.tmDim),
                           style: StrokeStyle(lineWidth: 1))

                // Target dot (top)
                let topRect = CGRect(x: cx - radius, y: topY - radius, width: radius*2, height: radius*2)
                ctx.fill(Path(ellipseIn: topRect), with: .color(Color(red: 0.85, green: 0.62, blue: 0.40)))
            }
        }
        .frame(height: 32)
    }
}

// MARK: - New mini visualizations

struct CharacterMini: View {
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                // Orb moving along sine path
                let x = size.width * 0.5 + size.width * 0.3 * CGFloat(sin(t * 0.8))
                let y = size.height * 0.5 + size.height * 0.35 * CGFloat(sin(t * 1.1))
                let r: CGFloat = 8
                // Glow
                let glowRect = CGRect(x: x - r * 1.6, y: y - r * 1.6, width: r * 3.2, height: r * 3.2)
                ctx.fill(Path(ellipseIn: glowRect), with: .color(Color.tmAccent.opacity(0.2)))
                // Orb
                let orbRect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: orbRect), with: .color(Color.tmAccent))
            }
        }
        .frame(height: 32)
    }
}

struct VibratoMini: View {
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let segments = 40
                var path = Path()
                for i in 0...segments {
                    let x = size.width * CGFloat(i) / CGFloat(segments)
                    let phase = Double(i) / Double(segments) * .pi * 6
                    let y = size.height * 0.5 + size.height * 0.35 * CGFloat(sin(phase + t * 5))
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                ctx.stroke(path, with: .color(Color.tmGood.opacity(0.75)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: 32)
    }
}

struct HissMini: View {
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let cx = size.width * 0.5
                let cy = size.height * 0.5
                // Expanding ripple circles
                for ring in 0..<3 {
                    let phase = (t * 0.8 + Double(ring) * 0.33).truncatingRemainder(dividingBy: 1.0)
                    let radius = phase * min(size.width, size.height) * 0.48
                    let opacity = (1.0 - phase) * 0.55
                    let rect = CGRect(x: cx - radius, y: cy - radius,
                                      width: radius * 2, height: radius * 2)
                    ctx.stroke(Path(ellipseIn: rect),
                               with: .color(Color(red: 0.878, green: 0.620, blue: 0.290).opacity(opacity)),
                               style: StrokeStyle(lineWidth: 1.5))
                }
                // Center dot
                let dotR: CGFloat = 4
                let dotRect = CGRect(x: cx - dotR, y: cy - dotR, width: dotR * 2, height: dotR * 2)
                ctx.fill(Path(ellipseIn: dotRect),
                         with: .color(Color(red: 0.878, green: 0.620, blue: 0.290)))
            }
        }
        .frame(height: 32)
    }
}
