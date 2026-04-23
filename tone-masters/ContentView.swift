//
//  ContentView.swift
//  tone-masters
//
//  Created by Yen Huynh on 2026-04-21.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine: AudioEngine
    @StateObject private var exerciseViewModel: ExerciseViewModel
    @StateObject private var findRangeViewModel: FindYourRangeViewModel
    @StateObject private var pitchTrailViewModel: PitchTrailViewModel
    @StateObject private var followSongViewModel: FollowSongViewModel
    @StateObject private var voiceSettings: VoiceSettings

    @StateObject private var audiationViewModel: AudiationViewModel
    @StateObject private var sirenViewModel: SirenViewModel
    @StateObject private var intervalViewModel: IntervalViewModel
    @StateObject private var echoMeViewModel: EchoMeViewModel
    @StateObject private var streakManager = StreakManager()

    @StateObject private var pitchCharacterViewModel: PitchCharacterViewModel
    @StateObject private var vibratoViewModel: VibratoViewModel
    @StateObject private var hissChallengeViewModel: HissChallengeViewModel
    @StateObject private var spectrogramViewModel: SpectrogramViewModel

    init() {
        let engine = AudioEngine()
        let tone = ToneGenerator(engine: engine.avEngine)
        let settings = VoiceSettings()
        _audioEngine = StateObject(wrappedValue: engine)
        _exerciseViewModel = StateObject(wrappedValue: ExerciseViewModel(audioEngine: engine, toneGenerator: tone))
        _findRangeViewModel = StateObject(wrappedValue: FindYourRangeViewModel(audioEngine: engine))
        _pitchTrailViewModel = StateObject(wrappedValue: PitchTrailViewModel(audioEngine: engine, settings: settings))
        _followSongViewModel = StateObject(wrappedValue: FollowSongViewModel(audioEngine: engine, settings: settings))
        _audiationViewModel = StateObject(wrappedValue: AudiationViewModel(audioEngine: engine, toneGenerator: tone, settings: settings))
        _sirenViewModel = StateObject(wrappedValue: SirenViewModel(audioEngine: engine, settings: settings))
        _intervalViewModel = StateObject(wrappedValue: IntervalViewModel(audioEngine: engine, toneGenerator: tone, settings: settings))
        _echoMeViewModel   = StateObject(wrappedValue: EchoMeViewModel(audioEngine: engine, toneGenerator: tone, settings: settings))
        _voiceSettings = StateObject(wrappedValue: settings)
        _pitchCharacterViewModel = StateObject(wrappedValue: PitchCharacterViewModel(audioEngine: engine, settings: settings))
        _vibratoViewModel = StateObject(wrappedValue: VibratoViewModel(audioEngine: engine, settings: settings))
        _hissChallengeViewModel = StateObject(wrappedValue: HissChallengeViewModel(audioEngine: engine))
        _spectrogramViewModel = StateObject(wrappedValue: SpectrogramViewModel(audioEngine: engine))
    }

    var body: some View {
        NavigationStack {
            ScalePickerView(
                exerciseViewModel: exerciseViewModel,
                findRangeViewModel: findRangeViewModel,
                pitchTrailViewModel: pitchTrailViewModel,
                followSongViewModel: followSongViewModel,
                audiationViewModel: audiationViewModel,
                sirenViewModel: sirenViewModel,
                intervalViewModel: intervalViewModel,
                echoMeViewModel: echoMeViewModel,
                pitchCharacterViewModel: pitchCharacterViewModel,
                vibratoViewModel: vibratoViewModel,
                hissChallengeViewModel: hissChallengeViewModel,
                spectrogramViewModel: spectrogramViewModel,
                streakManager: streakManager,
                voiceSettings: voiceSettings,
                audioEngine: audioEngine
            )
        }
        .preferredColorScheme(.dark)
        .task {
            await audioEngine.requestPermission()
            if audioEngine.permissionGranted {
                try? audioEngine.startEngine()
            }
        }
    }
}

#Preview {
    ContentView()
}
