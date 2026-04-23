import Foundation

extension SongLibrary {
    static let twinkleTwinkle: Song = {
        var b = SongBuilder(bpm: 120)

        // Twinkle twinkle little star
        b.note("C3"); b.note("C3"); b.note("G3"); b.note("G3")
        b.note("A3"); b.note("A3"); b.note("G3", beats: 2)

        // How I wonder what you are
        b.note("F3"); b.note("F3"); b.note("E3"); b.note("E3")
        b.note("D3"); b.note("D3"); b.note("C3", beats: 2)

        // Up above the world so high
        b.note("G3"); b.note("G3"); b.note("F3"); b.note("F3")
        b.note("E3"); b.note("E3"); b.note("D3", beats: 2)

        // Like a diamond in the sky
        b.note("G3"); b.note("G3"); b.note("F3"); b.note("F3")
        b.note("E3"); b.note("E3"); b.note("D3", beats: 2)

        // Twinkle twinkle little star (repeat)
        b.note("C3"); b.note("C3"); b.note("G3"); b.note("G3")
        b.note("A3"); b.note("A3"); b.note("G3", beats: 2)

        // How I wonder what you are (repeat)
        b.note("F3"); b.note("F3"); b.note("E3"); b.note("E3")
        b.note("D3"); b.note("D3"); b.note("C3", beats: 2)

        return b.build(title: "Twinkle Twinkle Little Star", genre: .childrens)
    }()
}
