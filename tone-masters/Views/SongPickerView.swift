import SwiftUI

struct SongPickerView: View {
    @ObservedObject var viewModel: FollowSongViewModel
    @State private var navigateToGame = false

    var body: some View {
        List(SongLibrary.all) { song in
            Button {
                viewModel.currentSong = song
                navigateToGame = true
            } label: {
                HStack {
                    Image(systemName: "music.quarternote.3")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(song.notes.count) notes · \(viewModel.timeString(song.totalDuration))")
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
        .listStyle(.insetGrouped)
        .navigationTitle("Follow the Song")
        .navigationDestination(isPresented: $navigateToGame) {
            FollowSongView(viewModel: viewModel)
        }
    }
}
