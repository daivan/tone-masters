import Foundation

/// Builds a Song using note names ("C3", "F#4") and durations.
/// Beat positions accumulate automatically — no manual counting.
///
/// Usage:
///   var b = SongBuilder(bpm: 120)
///   b.note("C3")          // 1 beat (default)
///   b.note("G3", beats: 2)
///   b.rest()              // 1 beat silence
///   let song = b.build(title: "My Song")
struct SongBuilder {

    // MARK: - Note name → MIDI

    /// Converts a note name like "C3", "F#4", "Bb2" to a MIDI number.
    /// Middle C = C4 = MIDI 60.
    static func midi(_ name: String) -> Int {
        let noteNames: [String: Int] = [
            "C": 0, "C#": 1, "Db": 1,
            "D": 2, "D#": 3, "Eb": 3,
            "E": 4, "Fb": 4,
            "F": 5, "F#": 6, "Gb": 6,
            "G": 7, "G#": 8, "Ab": 8,
            "A": 9, "A#": 10, "Bb": 10,
            "B": 11, "Cb": 11
        ]

        // Split "F#4" → pitch="F#", octave=4
        var pitchPart = ""
        var octavePart = ""
        var i = name.startIndex
        while i < name.endIndex {
            let c = name[i]
            if c.isLetter || c == "#" || c == "b" {
                let next = name.index(after: i)
                // "b" is only a flat if it follows a letter and isn't at start
                if c == "b" && !pitchPart.isEmpty &&
                   (next == name.endIndex || name[next].isNumber || name[next] == "-") {
                    pitchPart.append(c)
                } else if c == "b" && pitchPart.isEmpty {
                    // bare "b" shouldn't happen, skip
                    pitchPart.append(c)
                } else {
                    pitchPart.append(c)
                }
            } else {
                octavePart.append(c)
            }
            i = name.index(after: i)
        }

        guard let semitone = noteNames[pitchPart],
              let octave = Int(octavePart) else {
            assertionFailure("SongBuilder: unrecognized note name '\(name)'")
            return 60
        }
        return (octave + 1) * 12 + semitone
    }

    // MARK: - Builder

    private let bpm: Double
    private var notes: [SongNote] = []
    private var currentBeat: Double = 0

    init(bpm: Double) {
        self.bpm = bpm
    }

    /// Add a pitched note. Default duration is 1 beat.
    mutating func note(_ name: String, beats: Double = 1) {
        notes.append(SongNote(
            midiNote: SongBuilder.midi(name),
            startBeat: currentBeat,
            durationBeats: beats
        ))
        currentBeat += beats
    }

    /// Add a silence (no note block). Default duration is 1 beat.
    mutating func rest(beats: Double = 1) {
        currentBeat += beats
    }

    /// Jump to a specific beat (useful for pickup notes or non-linear songs).
    mutating func seek(to beat: Double) {
        currentBeat = beat
    }

    func build(title: String) -> Song {
        Song(title: title, bpm: bpm, notes: notes)
    }
}
