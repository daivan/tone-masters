import SwiftUI

struct ScalePickerView: View {
    @ObservedObject var exerciseViewModel: ExerciseViewModel
    @ObservedObject var findRangeViewModel: FindYourRangeViewModel
    @State private var navigateToExercise = false
    @State private var navigateToFindRange = false

    var body: some View {
        List {
            // Find Your Range mode
            Section {
                Button {
                    navigateToFindRange = true
                } label: {
                    HStack {
                        Image(systemName: "waveform.and.mic")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Find Your Range")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Sing freely and discover your range")
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

            // Scale drills
            Section(header: Text("Scale Drills")) {
                ForEach(ScaleLibrary.all) { scale in
                    Button {
                        exerciseViewModel.selectedScale = scale
                        navigateToExercise = true
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(scale.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(scale.notes.count) notes · \(scale.notes.first?.name ?? "") – \(scale.notes.last?.name ?? "")")
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
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Tone Masters")
        .navigationDestination(isPresented: $navigateToExercise) {
            ExerciseView(viewModel: exerciseViewModel)
        }
        .navigationDestination(isPresented: $navigateToFindRange) {
            FindYourRangeView(viewModel: findRangeViewModel)
        }
    }
}
