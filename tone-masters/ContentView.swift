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

    init() {
        let engine = AudioEngine()
        let tone = ToneGenerator(engine: engine.avEngine)
        let settings = VoiceSettings()
        _audioEngine = StateObject(wrappedValue: engine)
        _exerciseViewModel = StateObject(wrappedValue: ExerciseViewModel(audioEngine: engine, toneGenerator: tone))
        _findRangeViewModel = StateObject(wrappedValue: FindYourRangeViewModel(audioEngine: engine))
        _pitchTrailViewModel = StateObject(wrappedValue: PitchTrailViewModel(audioEngine: engine, settings: settings))
        _followSongViewModel = StateObject(wrappedValue: FollowSongViewModel(audioEngine: engine, settings: settings))
        _voiceSettings = StateObject(wrappedValue: settings)
    }

    var body: some View {
        NavigationStack {
            ScalePickerView(
                exerciseViewModel: exerciseViewModel,
                findRangeViewModel: findRangeViewModel,
                pitchTrailViewModel: pitchTrailViewModel,
                followSongViewModel: followSongViewModel,
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
