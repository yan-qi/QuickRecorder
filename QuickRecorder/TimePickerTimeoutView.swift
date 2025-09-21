// Time picker style interface for timeout configuration
struct TimePickerTimeoutView: View {
    @AppStorage("recordingTimeout") private var recordingTimeout: Int = 0
    @State private var isEnabled: Bool = false
    @State private var hours: Int = 0
    @State private var minutes: Int = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enable/disable toggle
            Toggle("Auto-stop Recording", isOn: $isEnabled)
                .onChange(of: isEnabled) { enabled in
                    if enabled {
                        recordingTimeout = hours * 60 + minutes
                    } else {
                        recordingTimeout = 0
                    }
                }

            if isEnabled {
                // Time picker interface
                HStack {
                    Text("Stop after:")

                    // Hours picker
                    Picker("Hours", selection: $hours) {
                        ForEach(0...23, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 60)

                    Text("hours")

                    // Minutes picker
                    Picker("Minutes", selection: $minutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 60)

                    Text("minutes")

                    Spacer()
                }
                .onChange(of: hours) { _ in updateTimeout() }
                .onChange(of: minutes) { _ in updateTimeout() }

                // Quick preset buttons
                HStack {
                    ForEach([
                        ("30m", 0, 30),
                        ("1h", 1, 0),
                        ("2h", 2, 0),
                        ("4h", 4, 0)
                    ], id: \.0) { preset in
                        Button(preset.0) {
                            hours = preset.1
                            minutes = preset.2
                            updateTimeout()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Spacer()
                }

                Text("Recording will automatically stop after \(formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isEnabled = recordingTimeout > 0
            if recordingTimeout > 0 {
                hours = recordingTimeout / 60
                minutes = recordingTimeout % 60
            }
        }
    }

    private func updateTimeout() {
        recordingTimeout = hours * 60 + minutes
    }

    private var formattedDuration: String {
        if hours == 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes == 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}