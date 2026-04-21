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

    init() {
        let engine = AudioEngine()
        let tone = ToneGenerator(engine: engine.avEngine)
        _audioEngine = StateObject(wrappedValue: engine)
        _exerciseViewModel = StateObject(wrappedValue: ExerciseViewModel(audioEngine: engine, toneGenerator: tone))
        _findRangeViewModel = StateObject(wrappedValue: FindYourRangeViewModel(audioEngine: engine))
    }

    var body: some View {
        NavigationStack {
            ScalePickerView(
                exerciseViewModel: exerciseViewModel,
                findRangeViewModel: findRangeViewModel
            )
        }
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
