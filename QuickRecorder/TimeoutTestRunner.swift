//
//  TimeoutTestRunner.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/21.
//

import Foundation

/// Test runner that can be called from the app to verify timeout functionality
class TimeoutTestRunner {

    /// Runs all timeout tests and returns results
    static func runAllTests() -> TestResults {
        var results = TestResults()

        print("🚀 Starting Timeout Functionality Tests...")

        do {
            // Test 1: Basic RecordingTimeoutManager functionality
            try testRecordingTimeoutManagerBasics()
            results.addPass("RecordingTimeoutManager basics")

            // Test 2: SCContext integration
            try testSCContextIntegration()
            results.addPass("SCContext integration")

            // Test 3: UI configuration values
            try testUIConfigurationValues()
            results.addPass("UI configuration")

            // Test 4: Pause/Resume with timing
            try testPauseResumeWithTiming()
            results.addPass("Pause/Resume functionality")

            // Test 5: Edge cases
            try testEdgeCases()
            results.addPass("Edge cases")

            // Test 6: Warning notifications
            try testWarningNotifications()
            results.addPass("Warning notifications")

            // Test 7: Memory management
            try testMemoryManagement()
            results.addPass("Memory management")

        } catch let error as TestError {
            results.addFailure(error.testName, error.message)
        } catch {
            results.addFailure("Unknown", error.localizedDescription)
        }

        return results
    }

    // MARK: - Individual Tests

    static func testRecordingTimeoutManagerBasics() throws {
        let manager = RecordingTimeoutManager()

        // Test initial state
        guard !manager.isActive else {
            throw TestError("RecordingTimeoutManager basics", "Manager should not be active initially")
        }

        guard !manager.isPaused else {
            throw TestError("RecordingTimeoutManager basics", "Manager should not be paused initially")
        }

        guard manager.remainingTime == 0 else {
            throw TestError("RecordingTimeoutManager basics", "Remaining time should be 0 initially")
        }

        // Test starting timeout
        manager.startTimeout(duration: 2.0)

        guard manager.isActive else {
            throw TestError("RecordingTimeoutManager basics", "Manager should be active after starting")
        }

        guard manager.duration == 2.0 else {
            throw TestError("RecordingTimeoutManager basics", "Duration should be 2.0 seconds")
        }

        guard manager.remainingTime > 1.8 && manager.remainingTime <= 2.0 else {
            throw TestError("RecordingTimeoutManager basics", "Remaining time should be close to 2.0 seconds")
        }

        // Test canceling
        manager.cancelTimeout()

        guard !manager.isActive else {
            throw TestError("RecordingTimeoutManager basics", "Manager should not be active after canceling")
        }

        print("  ✅ RecordingTimeoutManager basics test passed")
    }

    static func testSCContextIntegration() throws {
        // Test UserDefaults configuration
        ud.set(45, forKey: "recordingTimeout") // 45 minutes
        SCContext.configureTimeoutFromUserDefaults()

        guard SCContext.timeoutDuration == 2700 else { // 45 * 60 = 2700
            throw TestError("SCContext integration", "Timeout duration should be 2700 seconds (45 minutes)")
        }

        guard SCContext.isTimeoutEnabled else {
            throw TestError("SCContext integration", "Timeout should be enabled")
        }

        // Test disabled configuration
        ud.set(0, forKey: "recordingTimeout")
        SCContext.configureTimeoutFromUserDefaults()

        guard SCContext.timeoutDuration == 0 else {
            throw TestError("SCContext integration", "Timeout duration should be 0")
        }

        guard !SCContext.isTimeoutEnabled else {
            throw TestError("SCContext integration", "Timeout should be disabled")
        }

        // Test starting timeout
        ud.set(1, forKey: "recordingTimeout") // 1 minute for testing
        SCContext.startRecordingTimeout()

        guard SCContext.timeoutManager != nil else {
            throw TestError("SCContext integration", "Timeout manager should be created")
        }

        guard SCContext.timeoutStartTime != nil else {
            throw TestError("SCContext integration", "Start time should be set")
        }

        // Test stopping timeout
        SCContext.stopRecordingTimeout()

        guard SCContext.timeoutManager == nil else {
            throw TestError("SCContext integration", "Timeout manager should be nil after stopping")
        }

        guard SCContext.timeoutStartTime == nil else {
            throw TestError("SCContext integration", "Start time should be nil after stopping")
        }

        print("  ✅ SCContext integration test passed")
    }

    static func testUIConfigurationValues() throws {
        // Test status text generation for various timeout values
        let testCases: [(Int, String)] = [
            (0, "Recording will not automatically stop"),
            (1, "Recording will stop after 1 minute"),
            (30, "Recording will stop after 30 minutes"),
            (60, "Recording will stop after 1 hour"),
            (90, "Recording will stop after 1h 30m"),
            (120, "Recording will stop after 2 hours")
        ]

        for (minutes, expectedText) in testCases {
            let actualText = generateTimeoutStatusText(minutes: minutes)
            guard actualText == expectedText else {
                throw TestError("UI configuration", "Status text for \(minutes) minutes: expected '\(expectedText)', got '\(actualText)'")
            }
        }

        print("  ✅ UI configuration test passed")
    }

    static func testPauseResumeWithTiming() throws {
        let manager = RecordingTimeoutManager()
        manager.startTimeout(duration: 3.0) // 3 seconds

        // Wait a bit then pause
        Thread.sleep(forTimeInterval: 0.5)
        manager.pauseTimeout()

        guard manager.isPaused else {
            throw TestError("Pause/Resume", "Manager should be paused")
        }

        guard manager.isActive else {
            throw TestError("Pause/Resume", "Manager should still be active when paused")
        }

        let remainingWhenPaused = manager.remainingTime
        guard remainingWhenPaused < 2.6 && remainingWhenPaused > 2.0 else {
            throw TestError("Pause/Resume", "Remaining time when paused should be around 2.5 seconds, got \(remainingWhenPaused)")
        }

        // Wait while paused (time shouldn't change)
        Thread.sleep(forTimeInterval: 0.5)
        let remainingAfterPauseWait = manager.remainingTime
        let timeDifference = abs(remainingAfterPauseWait - remainingWhenPaused)

        guard timeDifference < 0.1 else {
            throw TestError("Pause/Resume", "Time should not decrease while paused, difference: \(timeDifference)")
        }

        // Resume
        manager.resumeTimeout()

        guard !manager.isPaused else {
            throw TestError("Pause/Resume", "Manager should not be paused after resume")
        }

        guard manager.isActive else {
            throw TestError("Pause/Resume", "Manager should still be active after resume")
        }

        // Time should start decreasing again
        Thread.sleep(forTimeInterval: 0.2)
        let remainingAfterResume = manager.remainingTime

        guard remainingAfterResume < remainingWhenPaused else {
            throw TestError("Pause/Resume", "Time should decrease after resume")
        }

        manager.cancelTimeout()
        print("  ✅ Pause/Resume functionality test passed")
    }

    static func testEdgeCases() throws {
        let manager = RecordingTimeoutManager()

        // Test invalid durations
        manager.startTimeout(duration: 0)
        guard !manager.isActive else {
            throw TestError("Edge cases", "Manager should not start with 0 duration")
        }

        manager.startTimeout(duration: -5)
        guard !manager.isActive else {
            throw TestError("Edge cases", "Manager should not start with negative duration")
        }

        // Test pause without start
        let manager2 = RecordingTimeoutManager()
        manager2.pauseTimeout() // Should not crash

        guard !manager2.isActive && !manager2.isPaused else {
            throw TestError("Edge cases", "Pause without start should be handled gracefully")
        }

        // Test multiple starts
        manager.startTimeout(duration: 2.0)
        let firstStartTime = manager.startTime

        Thread.sleep(forTimeInterval: 0.1)
        manager.startTimeout(duration: 1.0)
        let secondStartTime = manager.startTime

        guard firstStartTime != secondStartTime else {
            throw TestError("Edge cases", "Multiple starts should update start time")
        }

        guard manager.duration == 1.0 else {
            throw TestError("Edge cases", "Duration should be updated to latest value")
        }

        manager.cancelTimeout()
        print("  ✅ Edge cases test passed")
    }

    static func testWarningNotifications() throws {
        let manager = RecordingTimeoutManager()
        let delegate = TestDelegate()
        manager.delegate = delegate
        manager.warningThreshold = 0.3 // 300ms warning

        let expectation = TestExpectation()
        delegate.onWarning = { remainingTime in
            guard remainingTime > 0 && remainingTime < 0.4 else {
                expectation.failWith("Warning remaining time should be positive and less than 0.4s, got \(remainingTime)")
                return
            }
            expectation.fulfill()
        }

        manager.startTimeout(duration: 0.5) // 500ms timeout

        let warningReceived = expectation.wait(timeout: 1.0)
        guard warningReceived && !expectation.failed else {
            throw TestError("Warning notifications", expectation.failureMessage ?? "Warning notification not received")
        }

        print("  ✅ Warning notifications test passed")
    }

    static func testMemoryManagement() throws {
        weak var weakManager: RecordingTimeoutManager?

        autoreleasepool {
            let manager = RecordingTimeoutManager()
            weakManager = manager
            manager.startTimeout(duration: 1.0)
            manager.cancelTimeout()
        }

        // Give time for cleanup
        Thread.sleep(forTimeInterval: 0.1)

        guard weakManager == nil else {
            throw TestError("Memory management", "RecordingTimeoutManager should be deallocated")
        }

        print("  ✅ Memory management test passed")
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

// MARK: - Test Support Classes

struct TestError: Error {
    let testName: String
    let message: String

    init(_ testName: String, _ message: String) {
        self.testName = testName
        self.message = message
    }
}

class TestResults {
    private var passes: [String] = []
    private var failures: [(String, String)] = []

    func addPass(_ testName: String) {
        passes.append(testName)
        print("✅ PASS: \(testName)")
    }

    func addFailure(_ testName: String, _ message: String) {
        failures.append((testName, message))
        print("❌ FAIL: \(testName) - \(message)")
    }

    var allPassed: Bool {
        return failures.isEmpty
    }

    var summary: String {
        let totalTests = passes.count + failures.count
        let passCount = passes.count
        let failCount = failures.count

        var summary = "\n" + "=" * 50 + "\n"
        summary += "TEST RESULTS SUMMARY\n"
        summary += "=" * 50 + "\n"
        summary += "Total Tests: \(totalTests)\n"
        summary += "Passed: \(passCount)\n"
        summary += "Failed: \(failCount)\n"

        if !failures.isEmpty {
            summary += "\nFAILURES:\n"
            for (testName, message) in failures {
                summary += "  ❌ \(testName): \(message)\n"
            }
        }

        summary += "\n" + (allPassed ? "🎉 ALL TESTS PASSED!" : "⚠️  SOME TESTS FAILED") + "\n"
        summary += "=" * 50

        return summary
    }
}

class TestExpectation {
    private var fulfilled = false
    private(set) var failed = false
    private(set) var failureMessage: String?

    func fulfill() {
        fulfilled = true
    }

    func failWith(_ message: String) {
        failed = true
        failureMessage = message
    }

    func wait(timeout: TimeInterval) -> Bool {
        let endTime = Date().addingTimeInterval(timeout)

        while !fulfilled && !failed && Date() < endTime {
            Thread.sleep(forTimeInterval: 0.01)
        }

        return fulfilled
    }
}

class TestDelegate: RecordingTimeoutDelegate {
    var onWarning: ((TimeInterval) -> Void)?
    var onExpiration: (() -> Void)?

    func recordingTimeoutWarning(remainingTime: TimeInterval) {
        onWarning?(remainingTime)
    }

    func recordingTimeoutExpired() {
        onExpiration?()
    }
}

// MARK: - Extensions

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}