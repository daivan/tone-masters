import Foundation

struct RemediationTip {
    let icon: String   // SF Symbol
    let headline: String
    let detail: String
}

struct RemediationEngine {
    /// Generate a tip based on mean absolute cents deviation and overall hit rate.
    static func tip(meanAbsCents: Double, hitRate: Double) -> RemediationTip {
        if hitRate < 0.25 {
            return RemediationTip(icon: "ear.fill", headline: "Listen first",
                detail: "Before singing, really sit with the reference tone. Hum it silently, feel it resonate in your body, then open your mouth.")
        }
        if meanAbsCents > 60 {
            return RemediationTip(icon: "scope", headline: "Large pitch drift",
                detail: "You're moving significantly away from the target. Try singing quieter and listening harder — loud singing can mask intonation errors.")
        }
        if meanAbsCents > 35 {
            return RemediationTip(icon: "arrow.up.and.down.circle", headline: "Aim for the centre",
                detail: "Your pitch is in the ballpark but drifting. Focus on a steady breath column from your lower abdomen — support stabilises pitch.")
        }
        if hitRate < 0.6 {
            return RemediationTip(icon: "waveform.path", headline: "Inconsistent accuracy",
                detail: "Sustain each note longer before moving on. Practise one interval at a time slowly, rather than rushing through the phrase.")
        }
        return RemediationTip(icon: "checkmark.seal.fill", headline: "Strong accuracy",
            detail: "Your pitch control is solid. Next step: work on tone quality — experiment with vowel shape and resonance placement.")
    }
}
