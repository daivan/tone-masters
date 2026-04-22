import Foundation

enum SongLibrary {
    static let twinkleTwinkle: Song = {
        // C4=60, D4=62, E4=64, F4=65, G4=67, A4=69
        let phrase1: [SongNote] = [
            // "Twinkle twinkle little star"
            SongNote(midiNote: 60, startBeat:  0, durationBeats: 1),
            SongNote(midiNote: 60, startBeat:  1, durationBeats: 1),
            SongNote(midiNote: 67, startBeat:  2, durationBeats: 1),
            SongNote(midiNote: 67, startBeat:  3, durationBeats: 1),
            SongNote(midiNote: 69, startBeat:  4, durationBeats: 1),
            SongNote(midiNote: 69, startBeat:  5, durationBeats: 1),
            SongNote(midiNote: 67, startBeat:  6, durationBeats: 2),
        ]
        let phrase2: [SongNote] = [
            // "How I wonder what you are"
            SongNote(midiNote: 65, startBeat:  8, durationBeats: 1),
            SongNote(midiNote: 65, startBeat:  9, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 10, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 11, durationBeats: 1),
            SongNote(midiNote: 62, startBeat: 12, durationBeats: 1),
            SongNote(midiNote: 62, startBeat: 13, durationBeats: 1),
            SongNote(midiNote: 60, startBeat: 14, durationBeats: 2),
        ]
        let phrase3: [SongNote] = [
            // "Up above the world so high"
            SongNote(midiNote: 67, startBeat: 16, durationBeats: 1),
            SongNote(midiNote: 67, startBeat: 17, durationBeats: 1),
            SongNote(midiNote: 65, startBeat: 18, durationBeats: 1),
            SongNote(midiNote: 65, startBeat: 19, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 20, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 21, durationBeats: 1),
            SongNote(midiNote: 62, startBeat: 22, durationBeats: 2),
        ]
        let phrase4: [SongNote] = [
            // "Like a diamond in the sky"
            SongNote(midiNote: 67, startBeat: 24, durationBeats: 1),
            SongNote(midiNote: 67, startBeat: 25, durationBeats: 1),
            SongNote(midiNote: 65, startBeat: 26, durationBeats: 1),
            SongNote(midiNote: 65, startBeat: 27, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 28, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 29, durationBeats: 1),
            SongNote(midiNote: 62, startBeat: 30, durationBeats: 2),
        ]
        let phrase5: [SongNote] = [
            // "Twinkle twinkle little star" (repeat)
            SongNote(midiNote: 60, startBeat: 32, durationBeats: 1),
            SongNote(midiNote: 60, startBeat: 33, durationBeats: 1),
            SongNote(midiNote: 67, startBeat: 34, durationBeats: 1),
            SongNote(midiNote: 67, startBeat: 35, durationBeats: 1),
            SongNote(midiNote: 69, startBeat: 36, durationBeats: 1),
            SongNote(midiNote: 69, startBeat: 37, durationBeats: 1),
            SongNote(midiNote: 67, startBeat: 38, durationBeats: 2),
        ]
        let phrase6: [SongNote] = [
            // "How I wonder what you are" (repeat)
            SongNote(midiNote: 65, startBeat: 40, durationBeats: 1),
            SongNote(midiNote: 65, startBeat: 41, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 42, durationBeats: 1),
            SongNote(midiNote: 64, startBeat: 43, durationBeats: 1),
            SongNote(midiNote: 62, startBeat: 44, durationBeats: 1),
            SongNote(midiNote: 62, startBeat: 45, durationBeats: 1),
            SongNote(midiNote: 60, startBeat: 46, durationBeats: 2),
        ]
        return Song(
            title: "Twinkle Twinkle Little Star",
            bpm: 120,
            notes: phrase1 + phrase2 + phrase3 + phrase4 + phrase5 + phrase6
        )
    }()

    static let all: [Song] = [twinkleTwinkle]
}
