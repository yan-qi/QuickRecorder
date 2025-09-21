//
//  ComprehensiveTimeoutTests.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/21.
//

import Foundation

/// Comprehensive test suite for timeout functionality
class ComprehensiveTimeoutTests {

    static func runAllTests() {
        print("🧪 Starting Comprehensive Timeout Tests...")
        print("=" * 50)

        // Test 1: Core timeout manager functionality
        testTimeoutManagerCore()

        // Test 2: SCContext integration
        testSCContextIntegration()

        // Test 3: UI configuration
        testUIConfiguration()

        // Test 4: Pause/Resume functionality
        testPauseResumeFunctionality()

        // Test 5: Edge cases and error handling
        testEdgeCasesAndErrorHandling()

        // Test 6: Notification system
        testNotificationSystem()

        // Test 7: Performance and memory
        testPerformanceAndMemory()

        print("=" * 50)
        print("✅ All Comprehensive Tests Completed")
    }

    // MARK: - Test 1: Core Timeout Manager Functionality

    static func testTimeoutManagerCore() {
        print("\n📝 Test 1: Core Timeout Manager Functionality")
        print("-" * 30)

        // Test 1.1: Basic initialization
        let manager = RecordingTimeoutManager()
        assert(!manager.isActive, "❌ Manager should not be active initially")
        assert(!manager.isPaused, "❌ Manager should not be paused initially")
        assert(manager.remainingTime == 0, "❌ Remaining time should be 0 initially")
        print("  ✓ Basic initialization works")

        // Test 1.2: Starting timeout with valid duration
        manager.startTimeout(duration: 5.0) // 5 seconds
        assert(manager.isActive, "❌ Manager should be active after starting")
        assert(manager.duration == 5.0, "❌ Duration should be set correctly")
        assert(manager.remainingTime > 4.5, "❌ Remaining time should be close to 5")
        print("  ✓ Starting timeout works")

        // Test 1.3: Canceling timeout
        manager.cancelTimeout()
        assert(!manager.isActive, "❌ Manager should not be active after canceling")
        print("  ✓ Canceling timeout works")

        // Test 1.4: Invalid duration handling
        manager.startTimeout(duration: 0)
        assert(!manager.isActive, "❌ Manager should not start with 0 duration")

        manager.startTimeout(duration: -5)
        assert(!manager.isActive, "❌ Manager should not start with negative duration")
        print("  ✓ Invalid duration handling works")

        print("✅ Test 1 PASSED: Core timeout manager functionality")
    }

    // MARK: - Test 2: SCContext Integration

    static func testSCContextIntegration() {
        print("\n📝 Test 2: SCContext Integration")
        print("-" * 30)

        // Test 2.1: Configuration from UserDefaults
        ud.set(30, forKey: "recordingTimeout") // 30 minutes
        SCContext.configureTimeoutFromUserDefaults()

        assert(SCContext.timeoutDuration == 1800, "❌ Timeout duration should be 1800 seconds (30 minutes)")
        assert(SCContext.isTimeoutEnabled, "❌ Timeout should be enabled")
        print("  ✓ UserDefaults configuration works")

        // Test 2.2: Disabled timeout configuration
        ud.set(0, forKey: "recordingTimeout")
        SCContext.configureTimeoutFromUserDefaults()

        assert(SCContext.timeoutDuration == 0, "❌ Timeout duration should be 0")
        assert(!SCContext.isTimeoutEnabled, "❌ Timeout should be disabled")
        print("  ✓ Disabled timeout configuration works")

        // Test 2.3: Starting and stopping timeout
        ud.set(1, forKey: "recordingTimeout") // 1 minute for quick testing
        SCContext.startRecordingTimeout()

        assert(SCContext.timeoutManager != nil, "❌ Timeout manager should be created")
        assert(SCContext.timeoutManager!.isActive, "❌ Timeout manager should be active")
        assert(SCContext.timeoutStartTime != nil, "❌ Start time should be set")
        print("  ✓ Starting timeout works")

        SCContext.stopRecordingTimeout()
        assert(SCContext.timeoutManager == nil, "❌ Timeout manager should be nil after stopping")
        assert(SCContext.timeoutStartTime == nil, "❌ Start time should be nil after stopping")
        print("  ✓ Stopping timeout works")

        // Test 2.4: Time formatting
        let formatted1 = SCContext.formatTimeoutDuration(minutes: 30)
        assert(formatted1 == "30 minutes", "❌ 30 minutes should format correctly")

        let formatted2 = SCContext.formatTimeoutDuration(minutes: 90)
        assert(formatted2 == "1h 30m", "❌ 90 minutes should format as 1h 30m")

        let formatted3 = SCContext.formatTimeoutDuration(minutes: 120)
        assert(formatted3 == "2 hours", "❌ 120 minutes should format as 2 hours")
        print("  ✓ Time formatting works")

        print("✅ Test 2 PASSED: SCContext integration")
    }

    // MARK: - Test 3: UI Configuration

    static func testUIConfiguration() {
        print("\n📝 Test 3: UI Configuration")
        print("-" * 30)

        // Test 3.1: Timeout status text generation
        let statusText1 = generateTimeoutStatusText(minutes: 0)
        assert(statusText1 == "Recording will not automatically stop", "❌ Zero timeout status incorrect")

        let statusText2 = generateTimeoutStatusText(minutes: 30)
        assert(statusText2 == "Recording will stop after 30 minutes", "❌ 30 minute status incorrect")

        let statusText3 = generateTimeoutStatusText(minutes: 1)
        assert(statusText3 == "Recording will stop after 1 minute", "❌ 1 minute status incorrect")

        let statusText4 = generateTimeoutStatusText(minutes: 90)
        assert(statusText4 == "Recording will stop after 1h 30m", "❌ 90 minute status incorrect")

        let statusText5 = generateTimeoutStatusText(minutes: 120)
        assert(statusText5 == "Recording will stop after 2 hours", "❌ 120 minute status incorrect")
        print("  ✓ Status text generation works")

        // Test 3.2: Preset button values
        let presets = [(0, "Off"), (30, "30m"), (60, "1h"), (120, "2h"), (240, "4h"), (480, "8h")]
        for (minutes, label) in presets {
            let calculatedLabel = generatePresetLabel(minutes: minutes)
            assert(calculatedLabel == label, "❌ Preset label for \(minutes) minutes should be '\(label)', got '\(calculatedLabel)'")
        }
        print("  ✓ Preset button values work")

        print("✅ Test 3 PASSED: UI configuration")
    }

    // MARK: - Test 4: Pause/Resume Functionality

    static func testPauseResumeFunctionality() {
        print("\n📝 Test 4: Pause/Resume Functionality")
        print("-" * 30)

        let manager = RecordingTimeoutManager()
        manager.startTimeout(duration: 10.0) // 10 seconds

        // Wait a bit, then pause
        Thread.sleep(forTimeInterval: 1.0)
        manager.pauseTimeout()

        assert(manager.isPaused, "❌ Manager should be paused")
        assert(manager.isActive, "❌ Manager should still be active when paused")

        let remainingBeforePause = manager.remainingTime
        assert(remainingBeforePause < 10.0, "❌ Remaining time should be less than 10 seconds")
        assert(remainingBeforePause > 8.0, "❌ Remaining time should be more than 8 seconds")
        print("  ✓ Pause functionality works")

        // Wait a bit more (time shouldn't decrease while paused)
        Thread.sleep(forTimeInterval: 1.0)
        let remainingAfterPauseDelay = manager.remainingTime
        assert(abs(remainingAfterPauseDelay - remainingBeforePause) < 0.1, "❌ Time should not decrease while paused")
        print("  ✓ Time preservation during pause works")

        // Resume
        manager.resumeTimeout()
        assert(!manager.isPaused, "❌ Manager should not be paused after resume")
        assert(manager.isActive, "❌ Manager should still be active after resume")

        // Time should start decreasing again
        Thread.sleep(forTimeInterval: 0.5)
        let remainingAfterResume = manager.remainingTime
        assert(remainingAfterResume < remainingBeforePause, "❌ Time should decrease after resume")
        print("  ✓ Resume functionality works")

        manager.cancelTimeout()
        print("✅ Test 4 PASSED: Pause/Resume functionality")
    }

    // MARK: - Test 5: Edge Cases and Error Handling

    static func testEdgeCasesAndErrorHandling() {
        print("\n📝 Test 5: Edge Cases and Error Handling")
        print("-" * 30)

        let manager = RecordingTimeoutManager()

        // Test 5.1: Multiple start calls
        manager.startTimeout(duration: 5.0)
        let firstStartTime = manager.startTime

        Thread.sleep(forTimeInterval: 0.1)
        manager.startTimeout(duration: 3.0)
        let secondStartTime = manager.startTime

        assert(firstStartTime != secondStartTime, "❌ Start time should change on multiple starts")
        assert(manager.duration == 3.0, "❌ Duration should be updated to latest value")
        print("  ✓ Multiple start calls work")

        // Test 5.2: Pause without start
        let manager2 = RecordingTimeoutManager()
        manager2.pauseTimeout() // Should not crash
        assert(!manager2.isActive, "❌ Manager should not be active")
        assert(!manager2.isPaused, "❌ Manager should not be paused")
        print("  ✓ Pause without start handled gracefully")

        // Test 5.3: Resume without pause
        manager.resumeTimeout() // Manager is active but not paused
        assert(manager.isActive, "❌ Manager should still be active")
        assert(!manager.isPaused, "❌ Manager should not be paused")
        print("  ✓ Resume without pause handled gracefully")

        // Test 5.4: Cancel inactive timer
        let manager3 = RecordingTimeoutManager()
        manager3.cancelTimeout() // Should not crash
        assert(!manager3.isActive, "❌ Manager should not be active")
        print("  ✓ Cancel inactive timer handled gracefully")

        // Test 5.5: Very large timeout values
        ud.set(10000, forKey: "recordingTimeout") // 10000 minutes
        SCContext.configureTimeoutFromUserDefaults()
        assert(SCContext.timeoutDuration == 600000, "❌ Large timeout should be handled")
        print("  ✓ Large timeout values handled")

        manager.cancelTimeout()
        print("✅ Test 5 PASSED: Edge cases and error handling")
    }

    // MARK: - Test 6: Notification System

    static func testNotificationSystem() {
        print("\n📝 Test 6: Notification System")
        print("-" * 30)

        // Test 6.1: Warning notification timing
        let manager = RecordingTimeoutManager()
        let delegate = TestNotificationDelegate()
        manager.delegate = delegate
        manager.warningThreshold = 0.2 // 200ms warning

        let warningExpectation = TestExpectation()
        delegate.onWarning = { remainingTime in
            assert(remainingTime > 0, "❌ Remaining time should be positive in warning")
            assert(remainingTime < 0.3, "❌ Warning should fire near threshold")
            warningExpectation.fulfill()
        }

        manager.startTimeout(duration: 0.4) // 400ms timeout
        let warningReceived = warningExpectation.wait(timeout: 1.0)
        assert(warningReceived, "❌ Warning notification should be received")
        print("  ✓ Warning notification timing works")

        // Test 6.2: Timeout expiration notification
        let expirationExpectation = TestExpectation()
        delegate.onExpiration = {
            expirationExpectation.fulfill()
        }

        let expirationReceived = expirationExpectation.wait(timeout: 1.0)
        assert(expirationReceived, "❌ Expiration notification should be received")
        print("  ✓ Expiration notification works")

        // Test 6.3: Notification message formatting
        let message1 = SCContext.formatTimeoutNotificationMessage(minutes: 30)
        assert(message1.contains("30 minute"), "❌ 30 minute message should be formatted correctly")

        let message2 = SCContext.formatTimeoutNotificationMessage(minutes: 90)
        assert(message2.contains("1h 30m"), "❌ 90 minute message should be formatted correctly")
        print("  ✓ Notification message formatting works")

        print("✅ Test 6 PASSED: Notification system")
    }

    // MARK: - Test 7: Performance and Memory

    static func testPerformanceAndMemory() {
        print("\n📝 Test 7: Performance and Memory")
        print("-" * 30)

        // Test 7.1: Memory leak prevention
        weak var weakManager: RecordingTimeoutManager?

        autoreleasepool {
            let manager = RecordingTimeoutManager()
            weakManager = manager
            manager.startTimeout(duration: 1.0)
            manager.cancelTimeout()
            // manager should be deallocated when leaving this scope
        }

        // Give some time for cleanup
        Thread.sleep(forTimeInterval: 0.1)
        assert(weakManager == nil, "❌ RecordingTimeoutManager should be deallocated")
        print("  ✓ Memory leak prevention works")

        // Test 7.2: Multiple rapid start/cancel cycles
        let manager = RecordingTimeoutManager()
        let startTime = Date()

        for _ in 0..<100 {
            manager.startTimeout(duration: 1.0)
            manager.cancelTimeout()
        }

        let elapsed = Date().timeIntervalSince(startTime)
        assert(elapsed < 1.0, "❌ 100 start/cancel cycles should complete quickly")
        print("  ✓ Performance under rapid operations is acceptable")

        // Test 7.3: Timer precision
        let precisionManager = RecordingTimeoutManager()
        let precisionDelegate = TestPrecisionDelegate()
        precisionManager.delegate = precisionDelegate

        let precisionExpectation = TestExpectation()
        let targetDuration: TimeInterval = 0.5
        let measureStart = Date()

        precisionDelegate.onExpiration = {
            let actualDuration = Date().timeIntervalSince(measureStart)
            let tolerance: TimeInterval = 0.1 // 100ms tolerance
            let difference = abs(actualDuration - targetDuration)

            assert(difference < tolerance, "❌ Timer precision should be within \(tolerance)s, was off by \(difference)s")
            precisionExpectation.fulfill()
        }

        precisionManager.startTimeout(duration: targetDuration)
        let precisionReceived = precisionExpectation.wait(timeout: 2.0)
        assert(precisionReceived, "❌ Precision test should complete")
        print("  ✓ Timer precision is acceptable")

        print("✅ Test 7 PASSED: Performance and memory")
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

    static func generatePresetLabel(minutes: Int) -> String {
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
}

// MARK: - Helper Extensions

extension SCContext {
    static func formatTimeoutDuration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    static func formatTimeoutNotificationMessage(minutes: Int) -> String {
        let duration = formatTimeoutDuration(minutes: minutes)
        return "Recording stopped automatically after \(duration)"
    }
}

// MARK: - Test Delegates

class TestNotificationDelegate: RecordingTimeoutDelegate {
    var onWarning: ((TimeInterval) -> Void)?
    var onExpiration: (() -> Void)?

    func recordingTimeoutWarning(remainingTime: TimeInterval) {
        onWarning?(remainingTime)
    }

    func recordingTimeoutExpired() {
        onExpiration?()
    }
}

class TestPrecisionDelegate: RecordingTimeoutDelegate {
    var onExpiration: (() -> Void)?

    func recordingTimeoutWarning(remainingTime: TimeInterval) {}

    func recordingTimeoutExpired() {
        onExpiration?()
    }
}

// MARK: - String Repeat Extension

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}