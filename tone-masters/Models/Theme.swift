import SwiftUI

// MARK: - Tone Master design-system colors
extension Color {
    // Backgrounds
    static let tmBg        = Color(red: 0.055, green: 0.043, blue: 0.051)   // #0E0B0D
    static let tmSurface   = Color(red: 0.106, green: 0.086, blue: 0.094)   // #1B1618
    static let tmSurface2  = Color(red: 0.133, green: 0.110, blue: 0.122)   // #221C1F
    // Text
    static let tmInk       = Color(red: 0.957, green: 0.937, blue: 0.902)   // #F4EFE6
    static let tmDim       = Color(red: 0.957, green: 0.937, blue: 0.902).opacity(0.55)
    static let tmDimmer    = Color(red: 0.957, green: 0.937, blue: 0.902).opacity(0.28)
    // Borders
    static let tmLine      = Color.white.opacity(0.08)
    // Accent: mint ~oklch(0.78 0.16 160)
    static let tmAccent    = Color(red: 0.369, green: 0.796, blue: 0.631)
    static let tmAccentDim = Color(red: 0.369, green: 0.796, blue: 0.631).opacity(0.18)
    static let tmAccentInk = Color(red: 0.063, green: 0.188, blue: 0.133)
    // States
    static let tmGood      = Color(red: 0.369, green: 0.796, blue: 0.631)   // on-pitch
    static let tmWarn      = Color(red: 0.878, green: 0.420, blue: 0.290)   // orange miss
}

// MARK: - MIDI note name helper
func midiNoteName(_ midi: Int) -> String {
    let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    let octave = (midi / 12) - 1
    let index  = ((midi % 12) + 12) % 12
    return "\(names[index])\(octave)"
}

// MARK: - Voice-type label from center MIDI
func voiceTypeName(_ centerMidi: Int) -> String {
    switch centerMidi {
    case ..<48:  return "Bass"
    case 48..<52: return "Baritone"
    case 52..<56: return "Tenor / Alto"
    case 56..<60: return "Mezzo"
    default:     return "Soprano"
    }
}
