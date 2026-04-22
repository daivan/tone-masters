import SwiftUI
import Combine

/// Persisted user preferences. Shared across the app via @StateObject in ContentView.
final class VoiceSettings: ObservableObject {
    /// MIDI note number for the center of the pitch display window.
    /// Default: 60 (C4, middle C). The display always shows center ± 12 semitones (2 octaves total).
    @AppStorage("centerMidi") var centerMidi: Int = 60

    var midiLow: Double { Double(centerMidi - 12) }
    var midiHigh: Double { Double(centerMidi + 12) }

    /// All valid center notes: E2 (MIDI 40) to E5 (MIDI 76), keeping the window within a singable range.
    static let centerMidiRange = 40...76

    static func noteName(for midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F",
                     "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midi / 12) - 1
        let index = ((midi % 12) + 12) % 12
        return "\(names[index])\(octave)"
    }
}
