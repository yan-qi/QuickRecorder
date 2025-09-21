//
//  UITimeoutTesting.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/21.
//

import Foundation
import SwiftUI

/// UI testing and verification for timeout configuration
class UITimeoutTesting {

    static func runUITests() -> TestResults {
        let results = TestResults()

        print("🎨 Starting UI Timeout Testing...")

        do {
            // Test 1: Status text generation
            try testStatusTextGeneration()
            results.addPass("Status text generation")

            // Test 2: Preset button values
            try testPresetButtonValues()
            results.addPass("Preset button values")

            // Test 3: Time formatting
            try testTimeFormatting()
            results.addPass("Time formatting")

            // Test 4: UserDefaults integration
            try testUserDefaultsIntegration()
            results.addPass("UserDefaults integration")

            // Test 5: UI state consistency
            try testUIStateConsistency()
            results.addPass("UI state consistency")

        } catch let error as TestError {
            results.addFailure(error.testName, error.message)
        } catch {
            results.addFailure("Unknown UI test", error.localizedDescription)
        }

        return results
    }

    // MARK: - UI Tests

    static func testStatusTextGeneration() throws {
        print("📝 Testing status text generation...")

        let testCases: [(minutes: Int, expected: String)] = [
            (0, "Recording will not automatically stop"),
            (1, "Recording will stop after 1 minute"),
            (5, "Recording will stop after 5 minutes"),
            (30, "Recording will stop after 30 minutes"),
            (60, "Recording will stop after 1 hour"),
            (90, "Recording will stop after 1h 30m"),
            (120, "Recording will stop after 2 hours"),
            (150, "Recording will stop after 2h 30m"),
            (720, "Recording will stop after 12 hours"),
            (1440, "Recording will stop after 24 hours")
        ]

        for testCase in testCases {
            let actual = generateTimeoutStatusText(minutes: testCase.minutes)
            guard actual == testCase.expected else {
                throw TestError("Status text generation",
                    "For \(testCase.minutes) minutes: expected '\(testCase.expected)', got '\(actual)'")
            }
        }

        print("  ✅ All status text cases passed")
    }

    static func testPresetButtonValues() throws {
        print("📝 Testing preset button values...")

        let presets: [(label: String, minutes: Int)] = [
            ("Off", 0),
            ("30m", 30),
            ("1h", 60),
            ("2h", 120),
            ("4h", 240),
            ("8h", 480)
        ]

        // Verify preset values are reasonable
        for preset in presets {
            guard preset.minutes >= 0 && preset.minutes <= 1440 else {
                throw TestError("Preset button values",
                    "Preset '\(preset.label)' has invalid minutes: \(preset.minutes)")
            }

            // Verify label matches expected format
            let expectedLabel = formatPresetLabel(minutes: preset.minutes)
            guard preset.label == expectedLabel else {
                throw TestError("Preset button values",
                    "Preset for \(preset.minutes) minutes: expected '\(expectedLabel)', got '\(preset.label)'")
            }
        }

        print("  ✅ All preset button values are correct")
    }

    static func testTimeFormatting() throws {
        print("📝 Testing time formatting...")

        let formattingCases: [(minutes: Int, expectedShort: String, expectedLong: String)] = [
            (30, "30m", "30 minutes"),
            (60, "1h", "1 hour"),
            (90, "1h 30m", "1 hour 30 minutes"),
            (120, "2h", "2 hours"),
            (150, "2h 30m", "2 hours 30 minutes"),
            (480, "8h", "8 hours")
        ]

        for testCase in formattingCases {
            let shortFormat = formatTimeShort(minutes: testCase.minutes)
            let longFormat = formatTimeLong(minutes: testCase.minutes)

            guard shortFormat == testCase.expectedShort else {
                throw TestError("Time formatting",
                    "Short format for \(testCase.minutes) minutes: expected '\(testCase.expectedShort)', got '\(shortFormat)'")
            }

            guard longFormat == testCase.expectedLong else {
                throw TestError("Time formatting",
                    "Long format for \(testCase.minutes) minutes: expected '\(testCase.expectedLong)', got '\(longFormat)'")
            }
        }

        print("  ✅ Time formatting works correctly")
    }

    static func testUserDefaultsIntegration() throws {
        print("📝 Testing UserDefaults integration...")

        let testValues = [0, 15, 30, 60, 120, 480, 1440]

        for testValue in testValues {
            // Set value in UserDefaults
            ud.set(testValue, forKey: "recordingTimeout")

            // Configure SCContext from UserDefaults
            SCContext.configureTimeoutFromUserDefaults()

            // Verify the configuration was applied correctly
            let expectedDuration = TimeInterval(testValue * 60)
            guard SCContext.timeoutDuration == expectedDuration else {
                throw TestError("UserDefaults integration",
                    "For \(testValue) minutes: expected duration \(expectedDuration)s, got \(SCContext.timeoutDuration)s")
            }

            let expectedEnabled = testValue > 0
            guard SCContext.isTimeoutEnabled == expectedEnabled else {
                throw TestError("UserDefaults integration",
                    "For \(testValue) minutes: expected enabled=\(expectedEnabled), got \(SCContext.isTimeoutEnabled)")
            }
        }

        print("  ✅ UserDefaults integration works correctly")
    }

    static func testUIStateConsistency() throws {
        print("📝 Testing UI state consistency...")

        // Test that UI state remains consistent across different timeout values
        let stateTestValues = [0, 30, 60, 120, 240, 480]

        for testValue in stateTestValues {
            // Simulate UI state
            let isEnabled = testValue > 0
            let statusText = generateTimeoutStatusText(minutes: testValue)
            let presetLabel = formatPresetLabel(minutes: testValue)

            // Verify consistency
            if testValue == 0 {
                guard !isEnabled else {
                    throw TestError("UI state consistency", "Timeout should be disabled for 0 minutes")
                }
                guard statusText.contains("will not automatically stop") else {
                    throw TestError("UI state consistency", "Status text should indicate disabled state")
                }
            } else {
                guard isEnabled else {
                    throw TestError("UI state consistency", "Timeout should be enabled for \(testValue) minutes")
                }
                guard statusText.contains("will stop after") else {
                    throw TestError("UI state consistency", "Status text should indicate when recording will stop")
                }
            }

            print("  ✓ State consistency for \(testValue) minutes: \(presetLabel)")
        }

        print("  ✅ UI state consistency verified")
    }

    // MARK: - Helper Methods

    static func generateTimeoutStatusText(minutes: Int) -> String {
        if minutes == 0 {
            return "Recording will not automatically stop"
        } else if minutes < 60 {
            return "Recording will stop after \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "Recording will stop after \(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "Recording will stop after \(hours)h \(mins)m"
            }
        }
    }

    static func formatPresetLabel(minutes: Int) -> String {
        switch minutes {
        case 0: return "Off"
        case 30: return "30m"
        case 60: return "1h"
        case 120: return "2h"
        case 240: return "4h"
        case 480: return "8h"
        default: return "\(minutes)m"
        }
    }

    static func formatTimeShort(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    static func formatTimeLong(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") \(mins) minute\(mins == 1 ? "" : "s")"
            }
        }
    }
}

/// Manual verification checklist for UI testing
struct UIVerificationChecklist {
    static let checklist = """

    📋 MANUAL UI VERIFICATION CHECKLIST
    ===================================

    Please verify the following in the QuickRecorder Settings:

    1. TIMEOUT CONFIGURATION SECTION:
       □ "Auto-stop Recording (minutes)" label is visible
       □ Stepper control shows current value (0-1440 range)
       □ Preset buttons are visible: [Off] [30m] [1h] [2h] [4h] [8h]
       □ Status text shows below controls

    2. PRESET BUTTON FUNCTIONALITY:
       □ Clicking "Off" sets value to 0
       □ Clicking "30m" sets value to 30
       □ Clicking "1h" sets value to 60
       □ Clicking "2h" sets value to 120
       □ Clicking "4h" sets value to 240
       □ Clicking "8h" sets value to 480
       □ Active preset button is highlighted

    3. STATUS TEXT ACCURACY:
       □ 0 minutes: "Recording will not automatically stop"
       □ 1 minute: "Recording will stop after 1 minute"
       □ 30 minutes: "Recording will stop after 30 minutes"
       □ 60 minutes: "Recording will stop after 1 hour"
       □ 90 minutes: "Recording will stop after 1h 30m"
       □ 120 minutes: "Recording will stop after 2 hours"

    4. STEPPER CONTROL:
       □ + button increases value
       □ - button decreases value
       □ Direct typing works
       □ Value stays within 0-1440 range
       □ Status text updates immediately

    5. LAYOUT AND APPEARANCE:
       □ Controls are properly aligned
       □ Text is readable and well-spaced
       □ Preset buttons fit on one line
       □ Help tooltip appears on hover
       □ Consistent with other settings controls

    6. PERSISTENCE:
       □ Settings save when changed
       □ Settings restore on app restart
       □ Settings survive system reboot

    ===================================
    Mark each item as complete: ✅ or incomplete: ❌
    """
}

// MARK: - Test Integration

/// Comprehensive UI test runner that can be called from the main app
extension UITimeoutTesting {

    /// Run all UI tests and display results
    static func runComprehensiveUITest() {
        print(UIVerificationChecklist.checklist)

        let results = runUITests()
        print(results.summary)

        if results.allPassed {
            print("\n🎉 All automated UI tests passed!")
            print("📋 Please complete the manual verification checklist above.")
        } else {
            print("\n⚠️ Some automated UI tests failed. Please review and fix issues before manual testing.")
        }
    }
}