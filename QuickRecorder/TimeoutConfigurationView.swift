// Enhanced UI with preset options and custom input
struct TimeoutConfigurationView: View {
    @AppStorage("recordingTimeout") private var recordingTimeout: Int = 0
    @State private var showCustomInput = false

    private let presetOptions = [
        (label: "Disabled", minutes: 0),
        (label: "30 minutes", minutes: 30),
        (label: "1 hour", minutes: 60),
        (label: "2 hours", minutes: 120),
        (label: "4 hours", minutes: 240),
        (label: "8 hours", minutes: 480),
        (label: "Custom", minutes: -1)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Auto-stop Recording")
                .font(.headline)

            // Preset buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(presetOptions, id: \.minutes) { preset in
                    Button(action: {
                        if preset.minutes == -1 {
                            showCustomInput = true
                        } else {
                            recordingTimeout = preset.minutes
                            showCustomInput = false
                        }
                    }) {
                        Text(preset.label)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                recordingTimeout == preset.minutes ? Color.accentColor : Color.secondary.opacity(0.2)
                            )
                            .foregroundColor(
                                recordingTimeout == preset.minutes ? .white : .primary
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Custom input field
            if showCustomInput || !presetOptions.contains(where: { $0.minutes == recordingTimeout }) {
                HStack {
                    Text("Custom duration:")
                    TextField("Minutes", value: $recordingTimeout, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("minutes")
                    Spacer()
                }
            }

            // Current selection display
            Text(timeoutDisplayText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var timeoutDisplayText: String {
        if recordingTimeout == 0 {
            return "Recording will not automatically stop"
        } else if recordingTimeout < 60 {
            return "Recording will stop after \(recordingTimeout) minute\(recordingTimeout == 1 ? "" : "s")"
        } else {
            let hours = recordingTimeout / 60
            let minutes = recordingTimeout % 60
            if minutes == 0 {
                return "Recording will stop after \(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "Recording will stop after \(hours)h \(minutes)m"
            }
        }
    }
}