//
//  LongRecordingStabilityTests.swift
//  QuickRecorderTests
//
//  Created by Claude Code on 2025/09/20.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

final class LongRecordingStabilityTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    // MARK: - Memory Pressure Monitoring Tests

    func testMemoryPressureMonitoringExists() throws {
        // GIVEN: A recording session is active
        // WHEN: Memory pressure monitoring is checked
        // THEN: The system should have memory pressure detection capability

        let monitor = LongRecordingStabilityManager.shared
        XCTAssertNotNil(monitor.memoryPressureMonitor, "Memory pressure monitor should be initialized")
    }

    func testMemoryPressureThresholds() throws {
        // GIVEN: Various memory pressure states
        let testCases: [(ProcessInfo.ThermalState, Bool)] = [
            (.nominal, false),
            (.fair, false),
            (.serious, true),
            (.critical, true)
        ]

        // WHEN: Each pressure state is evaluated
        for (thermalState, shouldTrigger) in testCases {
            let shouldPause = LongRecordingStabilityManager.shouldPauseForMemoryPressure(thermalState)

            // THEN: The response should match expected behavior
            XCTAssertEqual(shouldPause, shouldTrigger,
                          "Memory pressure response incorrect for \(thermalState)")
        }
    }

    func testMemoryPressureCallbackFrequency() throws {
        // GIVEN: A memory pressure monitor with specific frequency
        let monitor = LongRecordingStabilityManager.shared

        // WHEN: Multiple sample buffers are processed
        var callbackCount = 0
        monitor.onMemoryPressureCheck = { callbackCount += 1 }

        // Simulate processing 1000 frames
        for _ in 0..<1000 {
            monitor.shouldCheckMemoryPressure()
        }

        // THEN: Callback should be triggered approximately every 1000 frames
        XCTAssertGreaterThan(callbackCount, 0, "Memory pressure should be checked at least once")
        XCTAssertLessThan(callbackCount, 10, "Memory pressure shouldn't be checked too frequently")
    }

    // MARK: - Audio Engine Restart Tests

    func testAudioEngineRestartTiming() throws {
        // GIVEN: An audio engine that has been running for over an hour
        let stabilityManager = LongRecordingStabilityManager.shared
        let mockStartTime = Date().addingTimeInterval(-3700) // 1 hour 1 minute ago

        // WHEN: Checking if restart is needed
        let needsRestart = stabilityManager.audioEngineNeedsRestart(startTime: mockStartTime)

        // THEN: Should indicate restart is needed
        XCTAssertTrue(needsRestart, "Audio engine should need restart after 1 hour")
    }

    func testAudioEngineRestartNotNeededEarly() throws {
        // GIVEN: An audio engine that has been running for less than an hour
        let stabilityManager = LongRecordingStabilityManager.shared
        let mockStartTime = Date().addingTimeInterval(-1800) // 30 minutes ago

        // WHEN: Checking if restart is needed
        let needsRestart = stabilityManager.audioEngineNeedsRestart(startTime: mockStartTime)

        // THEN: Should not indicate restart is needed
        XCTAssertFalse(needsRestart, "Audio engine should not need restart before 1 hour")
    }

    func testAudioEngineRestartExecution() throws {
        // GIVEN: A mock audio engine
        let mockEngine = MockAudioEngine()
        let stabilityManager = LongRecordingStabilityManager.shared

        // WHEN: Restart is executed
        stabilityManager.restartAudioEngine(mockEngine) { success in
            // THEN: Should complete successfully
            XCTAssertTrue(success, "Audio engine restart should succeed")
        }

        // THEN: Mock engine should show restart sequence
        XCTAssertTrue(mockEngine.wasStopCalled, "Audio engine stop should be called")
        XCTAssertTrue(mockEngine.wasResetCalled, "Audio engine reset should be called")
        XCTAssertTrue(mockEngine.wasStartCalled, "Audio engine start should be called")
    }

    // MARK: - Periodic File Flushing Tests

    func testFileFlushingInterval() throws {
        // GIVEN: A file flushing manager with 5-minute intervals
        let flushManager = PeriodicFileFlushManager()
        let mockFile = MockAudioFile()

        // WHEN: Checking if flush is needed after 6 minutes
        let sixMinutesAgo = Date().addingTimeInterval(-360)
        flushManager.lastFlushTime = sixMinutesAgo

        let needsFlush = flushManager.needsFlush()

        // THEN: Should indicate flush is needed
        XCTAssertTrue(needsFlush, "File should need flushing after 5+ minutes")
    }

    func testFileFlushingNotNeededEarly() throws {
        // GIVEN: A file flushing manager with recent flush
        let flushManager = PeriodicFileFlushManager()

        // WHEN: Checking if flush is needed after 2 minutes
        let twoMinutesAgo = Date().addingTimeInterval(-120)
        flushManager.lastFlushTime = twoMinutesAgo

        let needsFlush = flushManager.needsFlush()

        // THEN: Should not indicate flush is needed
        XCTAssertFalse(needsFlush, "File should not need flushing before 5 minutes")
    }

    func testFileFlushingExecution() throws {
        // GIVEN: Mock audio files
        let mockFile1 = MockAudioFile()
        let mockFile2 = MockAudioFile()
        let flushManager = PeriodicFileFlushManager()

        // WHEN: Flush is executed
        flushManager.flushMockFiles([mockFile1, mockFile2])

        // THEN: Both files should be flushed and timestamp updated
        XCTAssertTrue(mockFile1.wasFlushCalled, "First audio file should be flushed")
        XCTAssertTrue(mockFile2.wasFlushCalled, "Second audio file should be flushed")

        // Timestamp should be recent (within last 5 seconds)
        let timeSinceFlush = Date().timeIntervalSince(flushManager.lastFlushTime)
        XCTAssertLessThan(timeSinceFlush, 5.0, "Flush timestamp should be updated")
    }

    // MARK: - Integration Tests

    func testLongRecordingSimulation() throws {
        // GIVEN: A long recording simulation (2 hours compressed to seconds)
        let stabilityManager = LongRecordingStabilityManager.shared
        let mockStartTime = Date().addingTimeInterval(-7200) // 2 hours ago

        // WHEN: Running stability checks
        let memoryOK = !LongRecordingStabilityManager.shouldPauseForMemoryPressure(.nominal)
        let audioEngineNeedsRestart = stabilityManager.audioEngineNeedsRestart(startTime: mockStartTime)

        let flushManager = PeriodicFileFlushManager()
        flushManager.lastFlushTime = Date().addingTimeInterval(-400) // 6+ minutes ago
        let filesNeedFlush = flushManager.needsFlush()

        // THEN: All stability measures should be working
        XCTAssertTrue(memoryOK, "Memory should be okay under normal conditions")
        XCTAssertTrue(audioEngineNeedsRestart, "Audio engine should need restart after 2 hours")
        XCTAssertTrue(filesNeedFlush, "Files should need flushing after 6+ minutes")
    }

    func testStabilityManagerConfiguration() throws {
        // GIVEN: Default stability manager configuration
        let manager = LongRecordingStabilityManager.shared

        // WHEN: Checking configuration values
        // THEN: Should have reasonable defaults
        XCTAssertEqual(manager.memoryCheckFrequency, 1000, "Memory check should occur every 1000 frames")
        XCTAssertEqual(manager.audioEngineRestartInterval, 3600, "Audio engine restart should be every hour")
        XCTAssertEqual(manager.fileFlushInterval, 300, "File flush should be every 5 minutes")
    }
}

// MARK: - Mock Classes for Testing

class MockAudioEngine {
    var wasStopCalled = false
    var wasResetCalled = false
    var wasStartCalled = false

    func stop() {
        wasStopCalled = true
    }

    func reset() {
        wasResetCalled = true
    }

    func start() throws {
        wasStartCalled = true
    }
}

class MockAudioFile {
    var wasFlushCalled = false

    func flush() {
        wasFlushCalled = true
    }
}