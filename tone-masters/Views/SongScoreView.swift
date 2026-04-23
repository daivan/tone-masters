import SwiftUI

struct SongScoreView: View {
    @ObservedObject var viewModel: FollowSongViewModel
    @Binding var isPresented: Bool

    private var score: Int { viewModel.overallScore }

    private var scoreColor: Color {
        score >= 80 ? .green : score >= 50 ? .yellow : .red
    }

    private var scoreLabel: String {
        score >= 80 ? "Excellent!" : score >= 50 ? "Good job!" : "Keep practicing!"
    }

    private var genre: SongGenre { viewModel.currentSong.genre }

    private var genreColor: Color {
        switch genre {
        case .childrens:      return Color(red: 0.90, green: 0.70, blue: 0.30)
        case .folk:           return Color(red: 0.60, green: 0.80, blue: 0.55)
        case .pop:            return Color(red: 0.37, green: 0.80, blue: 0.63)
        case .musicalTheatre: return Color(red: 0.80, green: 0.45, blue: 0.70)
        case .jazz:           return Color(red: 0.85, green: 0.55, blue: 0.30)
        case .classical:      return Color(red: 0.55, green: 0.65, blue: 0.90)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(score)%")
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

                // Genre technique tip
                techniqueTipCard

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

    private var techniqueTipCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(genreColor)
                Text(genre.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(genreColor)
                    .kerning(1.2)
            }
            Text(genre.tip(forScore: score))
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(genreColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(genreColor.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}
