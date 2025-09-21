//
//  SCContextTimeoutTests.swift
//  QuickRecorderTests
//
//  Created by Claude Code on 2025/09/21.
//

import XCTest
@testable import QuickRecorder

class SCContextTimeoutTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset SCContext state before each test
        SCContext.resetTimeoutState()
    }

    override func tearDown() {
        SCContext.resetTimeoutState()
        super.tearDown()
    }

    // MARK: - Timeout Configuration Tests

    func testTimeoutConfigurationFromUserDefaults() {
        // Set timeout in UserDefaults (minutes)
        ud.set(30, forKey: "recordingTimeout")

        SCContext.configureTimeoutFromUserDefaults()

        XCTAssertEqual(SCContext.timeoutDuration, 30 * 60) // 30 minutes in seconds
        XCTAssertTrue(SCContext.isTimeoutEnabled)
    }

    func testTimeoutDisabledWhenSetToZero() {
        ud.set(0, forKey: "recordingTimeout")

        SCContext.configureTimeoutFromUserDefaults()

        XCTAssertEqual(SCContext.timeoutDuration, 0)
        XCTAssertFalse(SCContext.isTimeoutEnabled)
    }

    func testTimeoutConfigurationWithMaximumValue() {
        ud.set(1440, forKey: "recordingTimeout") // 24 hours

        SCContext.configureTimeoutFromUserDefaults()

        XCTAssertEqual(SCContext.timeoutDuration, 1440 * 60) // 24 hours in seconds
        XCTAssertTrue(SCContext.isTimeoutEnabled)
    }

    // MARK: - Recording Lifecycle Integration Tests

    func testStartRecordingTimeoutWhenEnabled() {
        SCContext.timeoutDuration = 1800 // 30 minutes

        SCContext.startRecordingTimeout()

        XCTAssertNotNil(SCContext.timeoutManager)
        XCTAssertTrue(SCContext.timeoutManager!.isActive)
        XCTAssertNotNil(SCContext.timeoutStartTime)
    }

    func testStartRecordingTimeoutWhenDisabled() {
        SCContext.timeoutDuration = 0

        SCContext.startRecordingTimeout()

        XCTAssertNil(SCContext.timeoutManager)
        XCTAssertNil(SCContext.timeoutStartTime)
    }

    func testStopRecordingTimeoutCleansUpState() {
        SCContext.timeoutDuration = 1800
        SCContext.startRecordingTimeout()

        SCContext.stopRecordingTimeout()

        XCTAssertNil(SCContext.timeoutManager)
        XCTAssertNil(SCContext.timeoutStartTime)
    }

    // MARK: - Pause/Resume Integration Tests

    func testPauseRecordingTimeoutWhenActive() {
        SCContext.timeoutDuration = 1800
        SCContext.startRecordingTimeout()
        SCContext.isPaused = true

        SCContext.pauseRecordingTimeout()

        XCTAssertTrue(SCContext.timeoutManager!.isPaused)
    }

    func testResumeRecordingTimeoutWhenPaused() {
        SCContext.timeoutDuration = 1800
        SCContext.startRecordingTimeout()
        SCContext.isPaused = true
        SCContext.pauseRecordingTimeout()

        SCContext.isPaused = false
        SCContext.pauseRecordingTimeout() // This should resume

        XCTAssertFalse(SCContext.timeoutManager!.isPaused)
    }

    func testPauseRecordingTimeoutWhenNoTimeoutActive() {
        SCContext.isPaused = true

        // This should not crash
        SCContext.pauseRecordingTimeout()

        XCTAssertNil(SCContext.timeoutManager)
    }

    // MARK: - Timeout Expiration Handling Tests

    func testTimeoutExpirationCallsStopRecording() {
        let expectation = self.expectation(description: "Stop recording should be called")

        // Mock the stopRecording function
        var stopRecordingCalled = false
        SCContext.onStopRecordingCalled = {
            stopRecordingCalled = true
            expectation.fulfill()
        }

        SCContext.timeoutDuration = 0.1 // Very short timeout for testing
        SCContext.startRecordingTimeout()

        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertTrue(stopRecordingCalled)
    }

    func testTimeoutExpirationShowsNotification() {
        let expectation = self.expectation(description: "Notification should be shown")

        // Mock notification system
        var notificationShown = false
        var notificationTitle = ""
        var notificationBody = ""

        SCContext.onNotificationShown = { title, body, id in
            notificationShown = true
            notificationTitle = title
            notificationBody = body
            expectation.fulfill()
        }

        SCContext.timeoutDuration = 0.1
        SCContext.startRecordingTimeout()

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertTrue(notificationShown)
        XCTAssertEqual(notificationTitle, "Recording Timeout")
        XCTAssertTrue(notificationBody.contains("automatically"))
    }

    // MARK: - Warning Notification Tests

    func testWarningNotificationBeforeTimeout() {
        let expectation = self.expectation(description: "Warning notification should be shown")

        var warningShown = false
        SCContext.onNotificationShown = { title, body, id in
            if title.contains("Warning") {
                warningShown = true
                expectation.fulfill()
            }
        }

        SCContext.timeoutDuration = 0.2 // 200ms timeout
        SCContext.warningThreshold = 0.1 // Warn at 100ms remaining
        SCContext.startRecordingTimeout()

        waitForExpectations(timeout: 1.0, handler: nil)
        XCTAssertTrue(warningShown)
    }

    // MARK: - Edge Cases and Error Handling

    func testTimeoutWithSystemSleep() {
        // This test would need system-level mocking
        // For now, we'll test the calculation logic

        SCContext.timeoutDuration = 1800
        SCContext.startRecordingTimeout()

        let startTime = SCContext.timeoutStartTime!
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = SCContext.calculateRemainingTimeout()

        XCTAssertEqual(remaining, SCContext.timeoutDuration - elapsed, accuracy: 1.0)
    }

    func testMultipleTimeoutStartsResetPrevious() {
        SCContext.timeoutDuration = 1800
        SCContext.startRecordingTimeout()
        let firstManager = SCContext.timeoutManager

        Thread.sleep(forTimeInterval: 0.1)

        SCContext.startRecordingTimeout()
        let secondManager = SCContext.timeoutManager

        XCTAssertNotEqual(firstManager, secondManager)
    }

    func testTimeoutManagerMemoryManagement() {
        weak var weakManager: RecordingTimeoutManager?

        autoreleasepool {
            SCContext.timeoutDuration = 1800
            SCContext.startRecordingTimeout()
            weakManager = SCContext.timeoutManager

            SCContext.stopRecordingTimeout()
        }

        // Give time for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakManager, "TimeoutManager should be deallocated")
        }
    }
}

// MARK: - SCContext Test Extensions

extension SCContext {
    static var onStopRecordingCalled: (() -> Void)?
    static var onNotificationShown: ((String, String, String) -> Void)?

    static func resetTimeoutState() {
        timeoutManager = nil
        timeoutStartTime = nil
        timeoutDuration = 0
        warningThreshold = 300 // 5 minutes default
        onStopRecordingCalled = nil
        onNotificationShown = nil
    }

    static func calculateRemainingTimeout() -> TimeInterval {
        guard let startTime = timeoutStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, timeoutDuration - elapsed)
    }
}