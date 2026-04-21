import SwiftUI

struct ScoreView: View {
    let result: ExerciseResult
    let onTryAgain: () -> Void
    let onChooseScale: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Score headline
                VStack(spacing: 8) {
                    Text("\(result.score) / \(result.total)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)

                    Text("notes in tune")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text(result.scaleName)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 32)

                Divider()

                // Per-note breakdown
                List(result.noteResults) { noteResult in
                    HStack {
                        Text(noteResult.note.name)
                            .font(.system(.body, design: .monospaced).bold())
                            .frame(width: 44, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.0f¢ avg deviation", noteResult.meanAbsCents))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: noteResult.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(noteResult.passed ? .green : .red)
                            .font(.title3)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onTryAgain) {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: onChooseScale) {
                        Label("Choose Scale", systemImage: "music.note.list")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var scoreColor: Color {
        let ratio = Double(result.score) / Double(max(result.total, 1))
        if ratio >= 0.75 { return .green }
        if ratio >= 0.5 { return .yellow }
        return .red
    }
}

#Preview {
    ScoreView(
        result: ExerciseResult(
            scaleName: "C Major",
            noteResults: [
                NoteResult(note: Note(name: "C4", frequency: 261.63, midiNumber: 60), meanAbsCents: 12),
                NoteResult(note: Note(name: "D4", frequency: 293.66, midiNumber: 62), meanAbsCents: 45),
                NoteResult(note: Note(name: "E4", frequency: 329.63, midiNumber: 64), meanAbsCents: 8),
            ]
        ),
        onTryAgain: {},
        onChooseScale: {}
    )
}
