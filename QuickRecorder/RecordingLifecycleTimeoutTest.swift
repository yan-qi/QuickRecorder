//
//  RecordingLifecycleTimeoutTest.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/21.
//

import Foundation

/// Integration test that simulates the complete recording lifecycle with timeout
class RecordingLifecycleTimeoutTest {

    static func runIntegrationTest() -> Bool {
        print("🎬 Starting Recording Lifecycle Integration Test...")
        print("-" * 50)

        do {
            // Test 1: Complete recording lifecycle with timeout
            try testCompleteRecordingLifecycle()

            // Test 2: Recording with pause/resume and timeout
            try testRecordingWithPauseResumeTimeout()

            // Test 3: Manual stop before timeout
            try testManualStopBeforeTimeout()

            // Test 4: Timeout configuration changes during recording
            try testTimeoutConfigurationChanges()

            print("✅ All integration tests passed!")
            return true

        } catch let error as TestError {
            print("❌ Integration test failed: \(error.testName) - \(error.message)")
            return false
        } catch {
            print("❌ Unexpected error: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Integration Tests

    static func testCompleteRecordingLifecycle() throws {
        print("📝 Test: Complete recording lifecycle with timeout")

        // Setup: Configure 2-second timeout for testing
        ud.set(0, forKey: "recordingTimeout") // Convert 2 seconds to minutes (for testing)
        SCContext.configureTimeoutFromUserDefaults()

        // Simulate recording start
        SCContext.startTime = Date()

        // Manually start timeout for testing (normally done by recording engine)
        SCContext.timeoutDuration = 2.0 // 2 seconds for quick testing
        SCContext.startRecordingTimeout()

        // Verify timeout is active
        guard SCContext.timeoutManager != nil else {
            throw TestError("Complete lifecycle", "Timeout manager should be created")
        }

        guard SCContext.timeoutManager!.isActive else {
            throw TestError("Complete lifecycle", "Timeout should be active")
        }

        print("  ✓ Recording started with timeout active")

        // Wait for a bit to verify timeout is counting down
        Thread.sleep(forTimeInterval: 0.5)

        let remainingTime = SCContext.getRemainingTimeoutDuration()
        guard remainingTime > 0 && remainingTime < 2.0 else {
            throw TestError("Complete lifecycle", "Remaining time should be decreasing")
        }

        print("  ✓ Timeout is counting down correctly (\(String(format: "%.1f", remainingTime))s remaining)")

        // Simulate recording stop (manual stop before timeout)
        SCContext.stopRecordingTimeout()
        SCContext.startTime = nil

        // Verify cleanup
        guard SCContext.timeoutManager == nil else {
            throw TestError("Complete lifecycle", "Timeout manager should be cleaned up")
        }

        print("  ✓ Manual stop before timeout works")
    }

    static func testRecordingWithPauseResumeTimeout() throws {
        print("📝 Test: Recording with pause/resume and timeout")

        // Setup 3-second timeout
        SCContext.timeoutDuration = 3.0
        SCContext.startRecordingTimeout()

        guard SCContext.timeoutManager != nil else {
            throw TestError("Pause/Resume lifecycle", "Timeout manager should be created")
        }

        // Simulate recording for a bit
        Thread.sleep(forTimeInterval: 0.5)

        // Simulate pause
        SCContext.isPaused = true
        SCContext.pauseRecordingTimeout()

        guard SCContext.timeoutManager!.isPaused else {
            throw TestError("Pause/Resume lifecycle", "Timeout should be paused")
        }

        let pausedRemainingTime = SCContext.getRemainingTimeoutDuration()
        print("  ✓ Recording paused, timeout paused with \(String(format: "%.1f", pausedRemainingTime))s remaining")

        // Wait while paused (time shouldn't decrease)
        Thread.sleep(forTimeInterval: 0.5)
        let remainingAfterPauseWait = SCContext.getRemainingTimeoutDuration()

        guard abs(remainingAfterPauseWait - pausedRemainingTime) < 0.1 else {
            throw TestError("Pause/Resume lifecycle", "Time should not decrease while paused")
        }

        print("  ✓ Time correctly preserved during pause")

        // Simulate resume
        SCContext.isPaused = false
        SCContext.pauseRecordingTimeout()

        guard !SCContext.timeoutManager!.isPaused else {
            throw TestError("Pause/Resume lifecycle", "Timeout should be resumed")
        }

        print("  ✓ Recording resumed, timeout resumed")

        // Clean up
        SCContext.stopRecordingTimeout()
    }

    static func testManualStopBeforeTimeout() throws {
        print("📝 Test: Manual stop before timeout expires")

        // Setup 5-second timeout
        SCContext.timeoutDuration = 5.0
        SCContext.startRecordingTimeout()

        // Simulate recording for 1 second
        Thread.sleep(forTimeInterval: 1.0)

        let remainingBeforeStop = SCContext.getRemainingTimeoutDuration()
        guard remainingBeforeStop > 3.0 && remainingBeforeStop < 5.0 else {
            throw TestError("Manual stop", "Remaining time should be around 4 seconds")
        }

        // Simulate manual stop
        SCContext.stopRecordingTimeout()

        guard SCContext.timeoutManager == nil else {
            throw TestError("Manual stop", "Timeout should be cleaned up after manual stop")
        }

        print("  ✓ Manual stop correctly cancels timeout")
    }

    static func testTimeoutConfigurationChanges() throws {
        print("📝 Test: Timeout configuration changes")

        // Test different timeout configurations
        let testConfigurations = [
            (minutes: 0, shouldBeEnabled: false, description: "disabled"),
            (minutes: 30, shouldBeEnabled: true, description: "30 minutes"),
            (minutes: 120, shouldBeEnabled: true, description: "2 hours"),
            (minutes: 1440, shouldBeEnabled: true, description: "24 hours")
        ]

        for config in testConfigurations {
            ud.set(config.minutes, forKey: "recordingTimeout")
            SCContext.configureTimeoutFromUserDefaults()

            let expectedDuration = TimeInterval(config.minutes * 60)
            guard SCContext.timeoutDuration == expectedDuration else {
                throw TestError("Configuration changes", "Duration for \(config.description) should be \(expectedDuration) seconds")
            }

            guard SCContext.isTimeoutEnabled == config.shouldBeEnabled else {
                throw TestError("Configuration changes", "Timeout enabled state for \(config.description) should be \(config.shouldBeEnabled)")
            }

            print("  ✓ Configuration \(config.description) works correctly")
        }
    }

    // MARK: - Mock Recording State Simulation

    /// Simulates the state changes that would happen during actual recording
    static func simulateRecordingStart() {
        SCContext.startTime = Date()
        SCContext.isPaused = false
        SCContext.startRecordingTimeout()
    }

    static func simulateRecordingPause() {
        SCContext.isPaused = true
        SCContext.pauseRecordingTimeout()
    }

    static func simulateRecordingResume() {
        SCContext.isPaused = false
        SCContext.pauseRecordingTimeout()
    }

    static func simulateRecordingStop() {
        SCContext.stopRecordingTimeout()
        SCContext.startTime = nil
        SCContext.isPaused = false
    }
}