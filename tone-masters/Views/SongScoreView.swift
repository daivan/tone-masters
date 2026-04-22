import SwiftUI

struct SongScoreView: View {
    @ObservedObject var viewModel: FollowSongViewModel
    @Binding var isPresented: Bool

    private var scoreColor: Color {
        viewModel.overallScore >= 80 ? .green :
        viewModel.overallScore >= 50 ? .yellow : .red
    }

    private var scoreLabel: String {
        viewModel.overallScore >= 80 ? "Excellent!" :
        viewModel.overallScore >= 50 ? "Good job!" : "Keep practicing!"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(viewModel.overallScore)%")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(scoreColor)
                    Text(scoreLabel)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                Divider()

                List(viewModel.finalScores, id: \.note.id) { item in
                    HStack {
                        Image(systemName: item.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.passed ? .green : .red)
                        Text(viewModel.noteName(for: item.note.midiNote + viewModel.transpositionOffset))
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Text("\(Int(item.hitRate * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .listStyle(.insetGrouped)

                Button("Play Again") {
                    isPresented = false
                    viewModel.restart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 24)
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}
