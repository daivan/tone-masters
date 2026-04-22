import Foundation

struct SongNote: Identifiable {
    let id = UUID()
    let midiNote: Int
    let startBeat: Double
    let durationBeats: Double

    func startTime(bpm: Double) -> Double { startBeat * 60.0 / bpm }
    func endTime(bpm: Double) -> Double   { (startBeat + durationBeats) * 60.0 / bpm }
    func durationTime(bpm: Double) -> Double { durationBeats * 60.0 / bpm }
}

struct Song: Identifiable {
    let id = UUID()
    let title: String
    let bpm: Double
    let notes: [SongNote]

    var totalDuration: Double {
        (notes.map { $0.startBeat + $0.durationBeats }.max() ?? 0) * 60.0 / bpm
    }
    var highestMidi: Int { notes.map(\.midiNote).max() ?? 60 }
    var lowestMidi:  Int { notes.map(\.midiNote).min() ?? 60 }

    /// Midpoint of the song's note range — used as the transposition anchor.
    var naturalCenterMidi: Int { (lowestMidi + highestMidi) / 2 }
}
