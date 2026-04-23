import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: VoiceSettings
    @ObservedObject private var limit    = DailyLimitManager.shared
    @ObservedObject private var reminder = RestReminderManager.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Center Note")
                        .font(.headline)

                    Text("Sets the middle of the pitch display window. The trail always shows 1 octave above and below this note.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Center Note", selection: $settings.centerMidi) {
                        ForEach(VoiceSettings.centerMidiRange, id: \.self) { (midi: Int) in
                            Text(VoiceSettings.noteName(for: midi)).tag(midi)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)

                    HStack {
                        Label("Display range", systemImage: "arrow.up.arrow.down")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(VoiceSettings.noteName(for: settings.centerMidi - 12)) – \(VoiceSettings.noteName(for: settings.centerMidi + 12))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Vocal Range")
            } footer: {
                Text("If you have a low voice, choose a lower center note (e.g. A2 or B2). If you have a high voice, try C4 or D4.")
            }

            Section {
                Toggle("Enable daily limit", isOn: $limit.isEnabled)
                if limit.isEnabled {
                    Stepper(
                        value: $limit.limitMinutes,
                        in: 10...120,
                        step: 5
                    ) {
                        HStack {
                            Text("Daily ceiling")
                            Spacer()
                            Text("\(limit.limitMinutes) min")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    HStack {
                        Text("Today so far")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(limit.todayMinutes) min")
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                }
            } header: {
                Text("Daily Practice Ceiling")
            } footer: {
                Text("Prevents vocal fatigue. Practice time resets at midnight. Includes all singing exercises.")
            }

            Section {
                Toggle("Enable rest reminders", isOn: $reminder.isEnabled)
                if reminder.isEnabled {
                    Stepper(
                        value: $reminder.reminderMinutes,
                        in: 5...60,
                        step: 5
                    ) {
                        HStack {
                            Text("Remind after")
                            Spacer()
                            Text("\(reminder.reminderMinutes) min")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Text("Rest Reminders")
            } footer: {
                Text("A notification fires if you stay in a single exercise for longer than the set time. It's cancelled automatically when you exit.")
            }

            Section("Presets") {
                presetButton(label: "Bass / Low voice", centerMidi: 45, icon: "tortoise.fill")       // A2
                presetButton(label: "Baritone / Alto", centerMidi: 50, icon: "minus.circle.fill")    // D3
                presetButton(label: "Tenor / Mezzo", centerMidi: 55, icon: "circle.fill")            // G3
                presetButton(label: "Soprano / High", centerMidi: 60, icon: "hare.fill")             // C4
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func presetButton(label: String, centerMidi: Int, icon: String) -> some View {
        Button {
            settings.centerMidi = centerMidi
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .foregroundStyle(.primary)
                    Text("Center: \(VoiceSettings.noteName(for: centerMidi))  ·  Range: \(VoiceSettings.noteName(for: centerMidi - 12))–\(VoiceSettings.noteName(for: centerMidi + 12))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if settings.centerMidi == centerMidi {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }
}
