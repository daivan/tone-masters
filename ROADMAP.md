# Tone Masters — Feature Roadmap

Check off items as they are completed. Each phase builds on the previous one.

---

## Phase 1 — Foundational Calibration

- [x] **Vocal range testing** — `FindYourRangeView` maps lowest and highest comfortable notes
- [x] **Voice type detection** — center MIDI determines Fach (Bass / Baritone / Tenor / Alto / Mezzo / Soprano)
- [x] **Auto-transposition** — all songs and exercises shift into the user's calibrated range
- [x] **Single-note matching** — scale drills: hear a reference tone, sing it back
- [x] **Cents-level accuracy display** — show deviation in cents (±100 = 1 semitone) in the info strip during exercises
- [x] **Audiation drills** — play a reference tone, silence it, user sings from memory; score with existing engine

---

## Phase 2 — Intervallic and Scalar Agility

- [x] **Scalar patterns** — scale drills with ascending/descending sequences
- [x] **Siren / portamento exercise** — guide user to glide across their full range; color pitch trail by register (chest/mix/head)
- [x] **Interval recognition game** — play two tones via ToneGenerator, user sings the second; game scores the leap accuracy
- [x] **Blind testing mode** — toggle that hides the pitch trail so user relies on internal ear only

---

## Phase 3 — Song-Based Application

- [x] **Follow the Song** — piano roll with scrolling note blocks and real-time pitch matching
- [x] **Song scoring** — per-note hit rate, overall %, green/red block history, results screen
- [x] **Song library** — `SongBuilder` DSL, one file per song, `SongLibrary.all` registry
- [x] **"Echo Me" drills** — play a pre-recorded melodic phrase, user mimics it; score with Follow the Song engine
- [x] **Stylistic nuance** — genre tags per song (pop, musical theatre, jazz); genre-specific technique tips shown after results

---

## Games and Drills

- [x] **Pitch-matching falling boxes** — Follow the Song is this
- [x] **Pitch-controlled character** — a character moves up/down on screen driven by the user's pitch; no target notes, low-stakes entry point for beginners
- [x] **Vibrato success zone** — detect pitch oscillation at 5–7 Hz; show an ellipse that turns green when vibrato rate is healthy
- [x] **Breath support hiss challenge** — detect sustained non-pitched audio (amplitude without clear pitch); timer counts while signal holds above threshold

---

## Real-Time Feedback

- [x] **Scrolling pitch graph** — Pitch Trail view shows voice history on a time axis
- [x] **Live block coloring** — active note turns green (on pitch) or orange (missing); passed notes turn green or red
- [x] **Cents display** — show `+12¢` / `-8¢` relative to nearest target note
- [x] **Actionable remediation** — rule-based tips after each session (e.g. "consistently flat → open mouth wider, engage core")
- [x] **Spectrogram view** — FFT via Accelerate `vDSP`, visualize harmonic overtones in Canvas at 30fps

---

## Safety and Engagement

- [x] **Practice streaks** — `@AppStorage` streak counter reset at midnight; shown on home screen
- [x] **XP and badges** — points per completed exercise; milestone badges (first song, 7-day streak, etc.)
- [x] **Daily practice ceiling** — configurable note or time limit to prevent vocal fatigue; resets daily
- [x] **Rest reminders** — push notification after X minutes of singing

---

## Infrastructure / Already Done

- [x] `AudioEngine` with exclusive ownership (UUID-based tap, auto-evict)
- [x] `ToneGenerator` for reference tones
- [x] YIN pitch detection
- [x] `VoiceSettings` with `@AppStorage` center MIDI
- [x] `SongBuilder` DSL (note names + auto beat tracking)
- [x] Editorial dark theme (`Theme.swift`)
- [x] `SongScoreView` results screen

---

## Build Order (recommended)

```
Now    →  Cents display, practice streaks, blind mode
Next   →  Audiation drills, interval game, siren exercise
Then   →  Echo Me, breath hiss, vibrato zone
Later  →  Spectrogram, character game, remediation tips
```
