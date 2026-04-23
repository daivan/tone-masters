import Foundation

// MARK: - Genre

enum SongGenre: String {
    case childrens      = "Children's"
    case folk           = "Folk"
    case pop            = "Pop"
    case musicalTheatre = "Musical Theatre"
    case jazz           = "Jazz"
    case classical      = "Classical"

    /// Three tips ordered: beginner (score < 50), intermediate (50–79), refined (≥ 80).
    var tips: [String] {
        switch self {
        case .childrens:
            return [
                "Relax your jaw and let the sound ring forward. Don't push — just breathe and speak the melody.",
                "Match the lightness of the tune. A gentle, pure tone works better here than a big sound.",
                "Try adding a small smile while you sing — it lifts the soft palate and brightens the tone naturally.",
            ]
        case .folk:
            return [
                "Keep the voice warm and easy. Folk singing values clarity and naturalness over power.",
                "Focus on the vowels — open them wide and let the melody float on the breath.",
                "Experiment with a light vibrato on held notes. Folk allows both straight tone and gentle oscillation.",
            ]
        case .pop:
            return [
                "Support each phrase with steady breath pressure. Popping off pitch usually means running out of air.",
                "Keep consonants crisp but vowels long — that's where the tone lives in pop style.",
                "Try a subtle belt on the highest notes: stay twangy in the pharynx, keep the larynx neutral.",
            ]
        case .musicalTheatre:
            return [
                "Project forward — imagine the sound landing at the back wall of a theatre, not in your throat.",
                "Emphasise consonants and tell the story; the audience hears words, not just notes.",
                "Mix chest and head voice deliberately. Clean register breaks are less important than intention and clarity.",
            ]
        case .jazz:
            return [
                "Relax the jaw and allow the voice to sit in a chest-mix blend for warmth and depth.",
                "Don't be afraid of slight pitch inflections — a small scoop into a note is a stylistic choice in jazz.",
                "Swing the rhythm: long-short pairs should feel lilting. Let the melody breathe between phrases.",
            ]
        case .classical:
            return [
                "Shape tall, vertical vowels — lift the soft palate as if you just smelled something wonderful.",
                "Maintain a steady breath column from below the navel. The support does the work, not the throat.",
                "Add a consistent vibrato of about 6 Hz. Think of it as the natural result of good support, not an ornament.",
            ]
        }
    }

    func tip(forScore score: Int) -> String {
        score < 50 ? tips[0] : score < 80 ? tips[1] : tips[2]
    }
}

// MARK: - Note

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
    let genre: SongGenre

    var totalDuration: Double {
        (notes.map { $0.startBeat + $0.durationBeats }.max() ?? 0) * 60.0 / bpm
    }
    var highestMidi: Int { notes.map(\.midiNote).max() ?? 60 }
    var lowestMidi:  Int { notes.map(\.midiNote).min() ?? 60 }

    /// Midpoint of the song's note range — used as the transposition anchor.
    var naturalCenterMidi: Int { (lowestMidi + highestMidi) / 2 }
}
