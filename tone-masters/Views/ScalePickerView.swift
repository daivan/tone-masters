import SwiftUI

struct ScalePickerView: View {
    @ObservedObject var exerciseViewModel: ExerciseViewModel
    @ObservedObject var findRangeViewModel: FindYourRangeViewModel
    @ObservedObject var pitchTrailViewModel: PitchTrailViewModel
    @ObservedObject var followSongViewModel: FollowSongViewModel
    @ObservedObject var voiceSettings: VoiceSettings
    @ObservedObject var audioEngine: AudioEngine
    @State private var navigateToExercise = false
    @State private var navigateToFindRange = false
    @State private var navigateToMicTest = false
    @State private var navigateToPitchTrail = false
    @State private var navigateToFollowSong = false
    @State private var navigateToSettings = false

    var body: some View {
        List {
            Section {
                Button { navigateToFindRange = true } label: {
                    modeRow(icon: "waveform.and.mic", color: .blue,
                            title: "Find Your Range",
                            subtitle: "Sing freely and discover your range")
                }

                Button { navigateToPitchTrail = true } label: {
                    modeRow(icon: "waveform.path.ecg", color: .cyan,
                            title: "Pitch Trail",
                            subtitle: "Watch your voice trace in real time")
                }

                Button { navigateToMicTest = true } label: {
                    modeRow(icon: "mic.badge.plus", color: .orange,
                            title: "Microphone Test",
                            subtitle: "Check if your mic is picking up sound")
                }
            }

            Section("Follow the Song") {
                Button { navigateToFollowSong = true } label: {
                    modeRow(icon: "music.quarternote.3", color: .orange,
                            title: "Follow the Song",
                            subtitle: "Sing along with a melody in real time")
                }
            }

            Section(header: Text("Scale Drills")) {
                ForEach(ScaleLibrary.all) { scale in
                    Button {
                        exerciseViewModel.selectedScale = scale
                        navigateToExercise = true
                    } label: {
                        modeRow(icon: "music.note", color: .purple,
                                title: scale.name,
                                subtitle: "\(scale.notes.count) notes · \(scale.notes.first?.name ?? "") – \(scale.notes.last?.name ?? "")")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tone Masters")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { navigateToSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
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

    private func modeRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
