import Foundation

struct Note: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let frequency: Double
    let midiNumber: Int
}

struct NoteResult: Identifiable {
    let id = UUID()
    let note: Note
    let meanAbsCents: Double
    var passed: Bool { meanAbsCents <= 30 }
}

struct ExerciseResult: Identifiable, Equatable {
    static func == (lhs: ExerciseResult, rhs: ExerciseResult) -> Bool {
        lhs.id == rhs.id
    }

    let id = UUID()
    let scaleName: String
    let noteResults: [NoteResult]
    var score: Int { noteResults.filter(\.passed).count }
    var total: Int { noteResults.count }
}

struct ScaleDefinition: Identifiable {
    let id = UUID()
    let name: String
    let notes: [Note]
}
