//
//  RecordingTimeoutManagerTests.swift
//  QuickRecorderTests
//
//  Created by Claude Code on 2025/09/21.
//

import XCTest
@testable import QuickRecorder

class RecordingTimeoutManagerTests: XCTestCase {
    var timeoutManager: RecordingTimeoutManager!
    var mockDelegate: MockTimeoutDelegate!

    override func setUp() {
        super.setUp()
        timeoutManager = RecordingTimeoutManager()
        mockDelegate = MockTimeoutDelegate()
        timeoutManager.delegate = mockDelegate
    }

    override func tearDown() {
        timeoutManager.cancelTimeout()
        timeoutManager = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Basic Timeout Tests

    func testTimeoutManagerInitialization() {
        XCTAssertNotNil(timeoutManager)
        XCTAssertFalse(timeoutManager.isActive)
        XCTAssertEqual(timeoutManager.duration, 0)
        XCTAssertNil(timeoutManager.startTime)
    }

    func testStartTimeoutWithValidDuration() {
        let duration: TimeInterval = 30 // 30 seconds

        timeoutManager.startTimeout(duration: duration)

        XCTAssertTrue(timeoutManager.isActive)
        XCTAssertEqual(timeoutManager.duration, duration)
        XCTAssertNotNil(timeoutManager.startTime)
    }

    func testStartTimeoutWithZeroDurationDoesNotStart() {
        timeoutManager.startTimeout(duration: 0)

        XCTAssertFalse(timeoutManager.isActive)
        XCTAssertNil(timeoutManager.startTime)
    }

    func testStartTimeoutWithNegativeDurationDoesNotStart() {
        timeoutManager.startTimeout(duration: -10)

        XCTAssertFalse(timeoutManager.isActive)
        XCTAssertNil(timeoutManager.startTime)
    }

    func testCancelTimeoutStopsActiveTimeout() {
        timeoutManager.startTimeout(duration: 60)
        XCTAssertTrue(timeoutManager.isActive)

        timeoutManager.cancelTimeout()

        XCTAssertFalse(timeoutManager.isActive)
        XCTAssertNil(timeoutManager.startTime)
    }

    // MARK: - Timeout Expiration Tests

    func testTimeoutExpirationCallsDelegate() {
        let expectation = self.expectation(description: "Timeout should expire")
        mockDelegate.onTimeoutExpired = {
            expectation.fulfill()
        }

        // Start with very short timeout for testing
        timeoutManager.startTimeout(duration: 0.1)

        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertTrue(mockDelegate.timeoutExpiredCalled)
    }

    func testTimeoutManagerBecomesInactiveAfterExpiration() {
        let expectation = self.expectation(description: "Timeout should expire")
        mockDelegate.onTimeoutExpired = {
            expectation.fulfill()
        }

        timeoutManager.startTimeout(duration: 0.1)

        waitForExpectations(timeout: 1.0, handler: nil)

        // Give a small delay for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.timeoutManager.isActive)
        }
    }

    // MARK: - Pause/Resume Tests

    func testPauseTimeoutStopsTimer() {
        timeoutManager.startTimeout(duration: 60)
        XCTAssertTrue(timeoutManager.isActive)

        timeoutManager.pauseTimeout()

        XCTAssertTrue(timeoutManager.isPaused)
        XCTAssertTrue(timeoutManager.isActive) // Still active, just paused
    }

    func testResumeTimeoutRestartsTimer() {
        timeoutManager.startTimeout(duration: 60)
        timeoutManager.pauseTimeout()

        timeoutManager.resumeTimeout()

        XCTAssertFalse(timeoutManager.isPaused)
        XCTAssertTrue(timeoutManager.isActive)
    }

    func testPauseTimeoutCalculatesRemainingTime() {
        timeoutManager.startTimeout(duration: 60)

        // Wait a small amount
        Thread.sleep(forTimeInterval: 0.1)

        timeoutManager.pauseTimeout()

        let remainingTime = timeoutManager.remainingTime
        XCTAssertLessThan(remainingTime, 60)
        XCTAssertGreaterThan(remainingTime, 59) // Should be close to 60
    }

    func testResumeTimeoutUsesRemainingTime() {
        timeoutManager.startTimeout(duration: 1.0)

        // Wait half the duration
        Thread.sleep(forTimeInterval: 0.5)

        timeoutManager.pauseTimeout()
        let remainingBeforeResume = timeoutManager.remainingTime

        timeoutManager.resumeTimeout()

        // Remaining time should be preserved
        XCTAssertEqual(timeoutManager.remainingTime, remainingBeforeResume, accuracy: 0.1)
    }

    // MARK: - Edge Cases

    func testMultipleStartCallsResetTimer() {
        timeoutManager.startTimeout(duration: 60)
        let firstStartTime = timeoutManager.startTime

        Thread.sleep(forTimeInterval: 0.1)

        timeoutManager.startTimeout(duration: 30)
        let secondStartTime = timeoutManager.startTime

        XCTAssertNotEqual(firstStartTime, secondStartTime)
        XCTAssertEqual(timeoutManager.duration, 30)
    }

    func testPauseWithoutStartDoesNothing() {
        timeoutManager.pauseTimeout()

        XCTAssertFalse(timeoutManager.isActive)
        XCTAssertFalse(timeoutManager.isPaused)
    }

    func testResumeWithoutPauseDoesNothing() {
        timeoutManager.startTimeout(duration: 60)

        timeoutManager.resumeTimeout() // Resume without pause

        XCTAssertTrue(timeoutManager.isActive)
        XCTAssertFalse(timeoutManager.isPaused)
    }

    // MARK: - Warning Notification Tests

    func testWarningNotificationSentAtConfiguredTime() {
        let expectation = self.expectation(description: "Warning should be sent")
        mockDelegate.onWarningTriggered = { remainingTime in
            XCTAssertEqual(remainingTime, 0.05, accuracy: 0.01) // 50ms warning
            expectation.fulfill()
        }

        // Set warning at 50ms before expiration
        timeoutManager.warningThreshold = 0.05
        timeoutManager.startTimeout(duration: 0.1)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testWarningNotificationSentOnlyOnce() {
        var warningCount = 0
        mockDelegate.onWarningTriggered = { _ in
            warningCount += 1
        }

        timeoutManager.warningThreshold = 0.05
        timeoutManager.startTimeout(duration: 0.1)

        // Wait for both warning and expiration
        Thread.sleep(forTimeInterval: 0.2)

        XCTAssertEqual(warningCount, 1)
    }
}

// MARK: - Mock Delegate

class MockTimeoutDelegate: RecordingTimeoutDelegate {
    var timeoutExpiredCalled = false
    var warningTriggeredCalled = false
    var onTimeoutExpired: (() -> Void)?
    var onWarningTriggered: ((TimeInterval) -> Void)?

    func recordingTimeoutExpired() {
        timeoutExpiredCalled = true
        onTimeoutExpired?()
    }

    func recordingTimeoutWarning(remainingTime: TimeInterval) {
        warningTriggeredCalled = true
        onWarningTriggered?(remainingTime)
    }
}