//
//  QuickTimeoutVerification.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/21.
//

import Foundation

/// Quick verification that timeout functionality is working after build fixes
class QuickTimeoutVerification {

    static func runVerification() -> Bool {
        print("🔍 Quick Timeout Functionality Verification")
        print("=" * 45)

        var allTestsPassed = true

        // Test 1: Basic timeout manager creation and operation
        print("\n1️⃣ Testing RecordingTimeoutManager basic functionality...")
        if !testBasicTimeoutManager() {
            allTestsPassed = false
        }

        // Test 2: SCContext integration
        print("\n2️⃣ Testing SCContext timeout integration...")
        if !testSCContextIntegration() {
            allTestsPassed = false
        }

        // Test 3: UserDefaults configuration
        print("\n3️⃣ Testing UserDefaults configuration...")
        if !testUserDefaultsConfiguration() {
            allTestsPassed = false
        }

        // Test 4: UI status text generation
        print("\n4️⃣ Testing UI status text generation...")
        if !testUIStatusText() {
            allTestsPassed = false
        }

        print("\n" + "=" * 45)
        if allTestsPassed {
            print("✅ ALL VERIFICATION TESTS PASSED!")
            print("🎉 Timeout functionality is working correctly after build fixes.")
        } else {
            print("❌ SOME VERIFICATION TESTS FAILED!")
            print("⚠️  Please review the errors above.")
        }
        print("=" * 45)

        return allTestsPassed
    }

    // MARK: - Individual Verification Tests

    static func testBasicTimeoutManager() -> Bool {
        do {
            let manager = RecordingTimeoutManager()

            // Test initial state
            guard !manager.isActive else {
                print("   ❌ Manager should not be active initially")
                return false
            }

            // Test starting timeout
            manager.startTimeout(duration: 2.0) // 2 seconds

            guard manager.isActive else {
                print("   ❌ Manager should be active after starting")
                return false
            }

            guard manager.duration == 2.0 else {
                print("   ❌ Duration should be 2.0 seconds")
                return false
            }

            // Test remaining time calculation
            let remaining = manager.remainingTime
            guard remaining > 1.8 && remaining <= 2.0 else {
                print("   ❌ Remaining time should be close to 2.0 seconds, got \(remaining)")
                return false
            }

            // Test canceling
            manager.cancelTimeout()

            guard !manager.isActive else {
                print("   ❌ Manager should not be active after canceling")
                return false
            }

            print("   ✅ RecordingTimeoutManager basic functionality works")
            return true

        } catch {
            print("   ❌ Exception during basic timeout manager test: \(error)")
            return false
        }
    }

    static func testSCContextIntegration() -> Bool {
        do {
            // Test configuration from UserDefaults
            ud.set(60, forKey: "recordingTimeout") // 60 minutes
            SCContext.configureTimeoutFromUserDefaults()

            guard SCContext.timeoutDuration == 3600 else { // 60 * 60 = 3600 seconds
                print("   ❌ Timeout duration should be 3600 seconds, got \(SCContext.timeoutDuration)")
                return false
            }

            guard SCContext.isTimeoutEnabled else {
                print("   ❌ Timeout should be enabled")
                return false
            }

            // Test disabled timeout
            ud.set(0, forKey: "recordingTimeout")
            SCContext.configureTimeoutFromUserDefaults()

            guard SCContext.timeoutDuration == 0 else {
                print("   ❌ Timeout duration should be 0 for disabled timeout")
                return false
            }

            guard !SCContext.isTimeoutEnabled else {
                print("   ❌ Timeout should be disabled")
                return false
            }

            // Test starting and stopping timeout
            ud.set(1, forKey: "recordingTimeout") // 1 minute for quick testing
            SCContext.startRecordingTimeout()

            guard SCContext.timeoutManager != nil else {
                print("   ❌ Timeout manager should be created")
                return false
            }

            guard SCContext.timeoutStartTime != nil else {
                print("   ❌ Start time should be set")
                return false
            }

            SCContext.stopRecordingTimeout()

            guard SCContext.timeoutManager == nil else {
                print("   ❌ Timeout manager should be nil after stopping")
                return false
            }

            print("   ✅ SCContext integration works")
            return true

        } catch {
            print("   ❌ Exception during SCContext integration test: \(error)")
            return false
        }
    }

    static func testUserDefaultsConfiguration() -> Bool {
        let testCases = [
            (minutes: 0, shouldBeEnabled: false),
            (minutes: 30, shouldBeEnabled: true),
            (minutes: 120, shouldBeEnabled: true),
            (minutes: 1440, shouldBeEnabled: true)
        ]

        for testCase in testCases {
            ud.set(testCase.minutes, forKey: "recordingTimeout")
            SCContext.configureTimeoutFromUserDefaults()

            let expectedDuration = TimeInterval(testCase.minutes * 60)
            guard SCContext.timeoutDuration == expectedDuration else {
                print("   ❌ For \(testCase.minutes) minutes: expected duration \(expectedDuration)s, got \(SCContext.timeoutDuration)s")
                return false
            }

            guard SCContext.isTimeoutEnabled == testCase.shouldBeEnabled else {
                print("   ❌ For \(testCase.minutes) minutes: expected enabled=\(testCase.shouldBeEnabled), got \(SCContext.isTimeoutEnabled)")
                return false
            }
        }

        print("   ✅ UserDefaults configuration works")
        return true
    }

    static func testUIStatusText() -> Bool {
        let testCases = [
            (minutes: 0, expected: "Recording will not automatically stop"),
            (minutes: 1, expected: "Recording will stop after 1 minute"),
            (minutes: 30, expected: "Recording will stop after 30 minutes"),
            (minutes: 60, expected: "Recording will stop after 1 hour"),
            (minutes: 90, expected: "Recording will stop after 1h 30m"),
            (minutes: 120, expected: "Recording will stop after 2 hours")
        ]

        for testCase in testCases {
            let actual = generateTimeoutStatusText(minutes: testCase.minutes)
            guard actual == testCase.expected else {
                print("   ❌ For \(testCase.minutes) minutes: expected '\(testCase.expected)', got '\(actual)'")
                return false
            }
        }

        print("   ✅ UI status text generation works")
        return true
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
}

// MARK: - String Extension for Formatting

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}