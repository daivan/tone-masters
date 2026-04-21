import Foundation

enum ScaleLibrary {
    static let cMajor: ScaleDefinition = ScaleDefinition(
        name: "C Major",
        notes: [
            Note(name: "C4",  frequency: 261.63, midiNumber: 60),
            Note(name: "D4",  frequency: 293.66, midiNumber: 62),
            Note(name: "E4",  frequency: 329.63, midiNumber: 64),
            Note(name: "F4",  frequency: 349.23, midiNumber: 65),
            Note(name: "G4",  frequency: 392.00, midiNumber: 67),
            Note(name: "A4",  frequency: 440.00, midiNumber: 69),
            Note(name: "B4",  frequency: 493.88, midiNumber: 71),
            Note(name: "C5",  frequency: 523.25, midiNumber: 72),
        ]
    )

    static let aMinor: ScaleDefinition = ScaleDefinition(
        name: "A Natural Minor",
        notes: [
            Note(name: "A3",  frequency: 220.00, midiNumber: 57),
            Note(name: "B3",  frequency: 246.94, midiNumber: 59),
            Note(name: "C4",  frequency: 261.63, midiNumber: 60),
            Note(name: "D4",  frequency: 293.66, midiNumber: 62),
            Note(name: "E4",  frequency: 329.63, midiNumber: 64),
            Note(name: "F4",  frequency: 349.23, midiNumber: 65),
            Note(name: "G4",  frequency: 392.00, midiNumber: 67),
            Note(name: "A4",  frequency: 440.00, midiNumber: 69),
        ]
    )

    static let all: [ScaleDefinition] = [cMajor, aMinor]
}
