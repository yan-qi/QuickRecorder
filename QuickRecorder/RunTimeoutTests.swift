//
//  RunTimeoutTests.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/21.
//

import Foundation

/// Entry point for running timeout functionality tests
/// This can be called from the main app or run as a standalone test
class RunTimeoutTests {

    /// Main entry point for testing
    static func main() {
        print("🚀 QuickRecorder Timeout Feature - Test Execution")
        print("=" * 50)
        print("Starting comprehensive test suite...")
        print("")

        // Run the complete test suite
        TimeoutTestOrchestrator.runCompleteTestSuite()

        print("\n" + "=" * 50)
        print("Test execution completed.")
        print("See results above for detailed information.")
    }

    /// Quick test for development verification
    static func runQuickTest() -> Bool {
        print("⚡ Running quick timeout functionality test...")

        do {
            // Quick basic functionality test
            let manager = RecordingTimeoutManager()
            manager.startTimeout(duration: 1.0)

            guard manager.isActive else {
                print("❌ Quick test failed: Manager not active")
                return false
            }

            Thread.sleep(forTimeInterval: 0.5)

            let remaining = manager.remainingTime
            guard remaining > 0 && remaining < 1.0 else {
                print("❌ Quick test failed: Remaining time not decreasing")
                return false
            }

            manager.cancelTimeout()

            guard !manager.isActive else {
                print("❌ Quick test failed: Manager still active after cancel")
                return false
            }

            // Quick SCContext test
            ud.set(30, forKey: "recordingTimeout")
            SCContext.configureTimeoutFromUserDefaults()

            guard SCContext.timeoutDuration == 1800 else {
                print("❌ Quick test failed: SCContext configuration incorrect")
                return false
            }

            print("✅ Quick test passed!")
            return true

        } catch {
            print("❌ Quick test failed with error: \(error.localizedDescription)")
            return false
        }
    }

    /// Test specific to a user-reported issue or scenario
    static func runScenarioTest(scenario: String) {
        print("🎯 Running scenario test: \(scenario)")

        switch scenario.lowercased() {
        case "long_recording":
            testLongRecordingScenario()
        case "pause_resume":
            testPauseResumeScenario()
        case "ui_interaction":
            testUIInteractionScenario()
        case "memory_leak":
            testMemoryLeakScenario()
        default:
            print("❌ Unknown scenario: \(scenario)")
            print("Available scenarios: long_recording, pause_resume, ui_interaction, memory_leak")
        }
    }

    // MARK: - Scenario Tests

    static func testLongRecordingScenario() {
        print("📹 Testing long recording scenario...")

        // Simulate 4-hour recording timeout
        ud.set(240, forKey: "recordingTimeout") // 4 hours
        SCContext.configureTimeoutFromUserDefaults()
        SCContext.startRecordingTimeout()

        guard SCContext.timeoutManager != nil else {
            print("❌ Failed to start long recording timeout")
            return
        }

        let remaining = SCContext.getRemainingTimeoutDuration()
        let expectedRemaining = 240 * 60 // 4 hours in seconds

        guard abs(remaining - TimeInterval(expectedRemaining)) < 1.0 else {
            print("❌ Long recording timeout not configured correctly")
            return
        }

        SCContext.stopRecordingTimeout()
        print("✅ Long recording scenario test passed")
    }

    static func testPauseResumeScenario() {
        print("⏸️ Testing pause/resume scenario...")

        let manager = RecordingTimeoutManager()
        manager.startTimeout(duration: 5.0)

        // Record, pause, resume cycle
        Thread.sleep(forTimeInterval: 1.0)

        manager.pauseTimeout()
        let pausedRemaining = manager.remainingTime

        Thread.sleep(forTimeInterval: 1.0) // Wait while paused

        let afterPauseRemaining = manager.remainingTime
        guard abs(afterPauseRemaining - pausedRemaining) < 0.1 else {
            print("❌ Time continued during pause")
            return
        }

        manager.resumeTimeout()
        Thread.sleep(forTimeInterval: 0.5)

        let resumedRemaining = manager.remainingTime
        guard resumedRemaining < pausedRemaining else {
            print("❌ Time didn't resume correctly")
            return
        }

        manager.cancelTimeout()
        print("✅ Pause/resume scenario test passed")
    }

    static func testUIInteractionScenario() {
        print("🎨 Testing UI interaction scenario...")

        // Test various UI state changes
        let testValues = [0, 30, 60, 120, 480]

        for value in testValues {
            ud.set(value, forKey: "recordingTimeout")
            SCContext.configureTimeoutFromUserDefaults()

            let expectedEnabled = value > 0
            guard SCContext.isTimeoutEnabled == expectedEnabled else {
                print("❌ UI state inconsistent for \(value) minutes")
                return
            }
        }

        print("✅ UI interaction scenario test passed")
    }

    static func testMemoryLeakScenario() {
        print("🧠 Testing memory leak scenario...")

        weak var weakManager: RecordingTimeoutManager?

        autoreleasepool {
            let manager = RecordingTimeoutManager()
            weakManager = manager

            // Simulate rapid operations
            for _ in 0..<100 {
                manager.startTimeout(duration: 1.0)
                manager.pauseTimeout()
                manager.resumeTimeout()
                manager.cancelTimeout()
            }
        }

        // Force cleanup
        autoreleasepool {}
        Thread.sleep(forTimeInterval: 0.1)

        guard weakManager == nil else {
            print("❌ Memory leak detected - manager not deallocated")
            return
        }

        print("✅ Memory leak scenario test passed")
    }

    // MARK: - Helper Methods

    /// Generate a test report for CI/CD or automated testing
    static func generateTestReport() -> String {
        let results = TimeoutTestRunner.runAllTests()

        var report = """
        QUICKRECORDER TIMEOUT FEATURE - TEST REPORT
        ===========================================
        Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))

        SUMMARY:
        - Total Tests: \(results.passes.count + results.failures.count)
        - Passed: \(results.passes.count)
        - Failed: \(results.failures.count)
        - Overall Status: \(results.allPassed ? "PASS" : "FAIL")

        """

        if !results.failures.isEmpty {
            report += "FAILURES:\n"
            for failure in results.failures {
                report += "- \(failure.0): \(failure.1)\n"
            }
        }

        report += "\nPASSED TESTS:\n"
        for pass in results.passes {
            report += "- \(pass)\n"
        }

        return report
    }
}

// MARK: - Console Application Support

#if canImport(Darwin)
/// If running as a standalone console application
if CommandLine.arguments.contains("--run-tests") {
    RunTimeoutTests.main()
} else if CommandLine.arguments.contains("--quick-test") {
    let success = RunTimeoutTests.runQuickTest()
    exit(success ? 0 : 1)
} else if let scenarioIndex = CommandLine.arguments.firstIndex(of: "--scenario"),
          scenarioIndex + 1 < CommandLine.arguments.count {
    let scenario = CommandLine.arguments[scenarioIndex + 1]
    RunTimeoutTests.runScenarioTest(scenario: scenario)
} else if CommandLine.arguments.contains("--help") {
    print("""
    QuickRecorder Timeout Tests

    Usage:
      --run-tests     Run complete test suite
      --quick-test    Run quick functionality test
      --scenario X    Run specific scenario test
      --help          Show this help

    Available scenarios:
      long_recording  Test long recording timeout
      pause_resume    Test pause/resume functionality
      ui_interaction  Test UI state changes
      memory_leak     Test memory management
    """)
}
#endif