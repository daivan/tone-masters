import Foundation

extension SongLibrary {
    static let happyBirthday: Song = {
        var b = SongBuilder(bpm: 100)

        // "Hap-py birth-day to you" ×2
        b.note("C3", beats: 0.75); b.note("C3", beats: 0.25)
        b.note("D3"); b.note("C3"); b.note("F3"); b.note("E3", beats: 2)

        b.note("C3", beats: 0.75); b.note("C3", beats: 0.25)
        b.note("D3"); b.note("C3"); b.note("G3"); b.note("F3", beats: 2)

        // "Hap-py birth-day dear [name]"
        b.note("C3", beats: 0.75); b.note("C3", beats: 0.25)
        b.note("C4"); b.note("A3"); b.note("F3"); b.note("E3"); b.note("D3", beats: 2)

        // "Hap-py birth-day to you"
        b.note("Bb3", beats: 0.75); b.note("Bb3", beats: 0.25)
        b.note("A3"); b.note("F3"); b.note("G3"); b.note("F3", beats: 2)

        return b.build(title: "Happy Birthday", genre: .pop)
    }()
}
