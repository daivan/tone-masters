import Foundation

struct NoteScore {
    let note: SongNote
    let hitFrames: Int
    let totalFrames: Int

    var hitRate: Double { totalFrames > 0 ? Double(hitFrames) / Double(totalFrames) : 0 }
    var passed: Bool { hitRate >= 0.5 }
}
