// Slider-based timeout configuration with smart intervals
struct SliderTimeoutView: View {
    @AppStorage("recordingTimeout") private var recordingTimeout: Int = 0
    @State private var sliderValue: Double = 0
    @State private var isEnabled: Bool = false

    // Smart intervals: more granular for shorter times, less for longer
    private let timeIntervals: [Int] = [
        0,      // Disabled
        5, 10, 15, 30,        // 5-30 minutes (5 min increments)
        45, 60, 90,           // 45 min - 1.5 hours (15-30 min increments)
        120, 180, 240, 300,   // 2-5 hours (1 hour increments)
        360, 480, 600, 720,   // 6-12 hours (2-4 hour increments)
        960, 1200, 1440       // 16-24 hours (4-8 hour increments)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Auto-stop Recording", isOn: $isEnabled)
                .onChange(of: isEnabled) { enabled in
                    if !enabled {
                        recordingTimeout = 0
                        sliderValue = 0
                    } else if recordingTimeout == 0 {
                        recordingTimeout = 30
                        sliderValue = Double(timeIntervals.firstIndex(of: 30) ?? 4)
                    }
                }

            if isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration: \(formattedDuration)")
                        .font(.subheadline)

                    Slider(
                        value: $sliderValue,
                        in: 1...Double(timeIntervals.count - 1),
                        step: 1
                    ) {
                        Text("Timeout Duration")
                    } minimumValueLabel: {
                        Text("5m")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("24h")
                            .font(.caption2)
                    }
                    .onChange(of: sliderValue) { value in
                        let index = Int(value)
                        recordingTimeout = timeIntervals[index]
                    }

                    // Quick access marks below slider
                    HStack {
                        ForEach([
                            (label: "30m", index: 4),
                            (label: "1h", index: 6),
                            (label: "2h", index: 9),
                            (label: "4h", index: 11),
                            (label: "8h", index: 13)
                        ], id: \.label) { mark in
                            Button(mark.label) {
                                sliderValue = Double(mark.index)
                                recordingTimeout = timeIntervals[mark.index]
                            }
                            .buttonStyle(.borderless)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            Spacer()
                        }
                    }

                    Text("Recording will stop automatically after the selected duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            isEnabled = recordingTimeout > 0
            if recordingTimeout > 0 {
                sliderValue = Double(findClosestIntervalIndex(recordingTimeout))
            }
        }
    }

    private func findClosestIntervalIndex(_ minutes: Int) -> Int {
        var bestIndex = 0
        var bestDifference = abs(timeIntervals[0] - minutes)

        for (index, interval) in timeIntervals.enumerated() {
            let difference = abs(interval - minutes)
            if difference < bestDifference {
                bestDifference = difference
                bestIndex = index
            }
        }

        return bestIndex
    }

    private var formattedDuration: String {
        if recordingTimeout < 60 {
            return "\(recordingTimeout) minute\(recordingTimeout == 1 ? "" : "s")"
        } else {
            let hours = recordingTimeout / 60
            let minutes = recordingTimeout % 60
            if minutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }
}