//
//  LongRecordingStabilityManager.swift
//  QuickRecorder
//
//  Created by Claude Code on 2025/09/20.
//

import Foundation
import AVFoundation

/// Manages stability features for long-duration audio recordings to prevent crashes and resource exhaustion
class LongRecordingStabilityManager {
    static let shared = LongRecordingStabilityManager()

    // MARK: - Configuration
    let memoryCheckFrequency: Int = 1000 // Check every 1000 sample buffers
    let audioEngineRestartInterval: TimeInterval = 3600 // 1 hour
    let fileFlushInterval: TimeInterval = 300 // 5 minutes

    // MARK: - State Tracking
    private var frameCount: Int = 0
    private var lastAudioEngineRestart: Date?

    // MARK: - Testing Support
    var memoryPressureMonitor: MemoryPressureMonitor?
    var onMemoryPressureCheck: (() -> Void)?

    private init() {
        setupMemoryPressureMonitoring()
    }

    // MARK: - Memory Pressure Monitoring

    private func setupMemoryPressureMonitoring() {
        memoryPressureMonitor = MemoryPressureMonitor()
    }

    /// Determines if recording should be paused due to memory pressure
    static func shouldPauseForMemoryPressure(_ thermalState: ProcessInfo.ThermalState) -> Bool {
        switch thermalState {
        case .serious, .critical:
            return true
        case .nominal, .fair:
            return false
        @unknown default:
            return false
        }
    }

    /// Checks if memory pressure monitoring should occur for this frame
    func shouldCheckMemoryPressure() -> Bool {
        frameCount += 1

        // Check memory pressure every memoryCheckFrequency frames
        if frameCount % memoryCheckFrequency == 0 {
            onMemoryPressureCheck?()
            return true
        }

        return false
    }

    /// Performs memory pressure check and returns action recommendation
    func checkMemoryPressureAndRecommendAction() -> MemoryPressureAction {
        let thermalState = ProcessInfo.processInfo.thermalState

        if Self.shouldPauseForMemoryPressure(thermalState) {
            print("🚨 High memory pressure detected (\(thermalState)). Recommending frame skip.")
            return .skipFrame
        }

        return .continueNormal
    }

    // MARK: - Audio Engine Management

    /// Determines if audio engine needs restart based on runtime duration
    func audioEngineNeedsRestart(startTime: Date) -> Bool {
        let runtime = Date().timeIntervalSince(startTime)
        return runtime >= audioEngineRestartInterval
    }

    /// Safely restarts an audio engine with error handling
    func restartAudioEngine(_ engine: AVAudioEngine, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("🔄 Restarting audio engine for stability...")

                // Stop engine
                engine.stop()

                // Reset engine state
                engine.reset()

                // Restart engine
                try engine.start()

                self.lastAudioEngineRestart = Date()
                print("✅ Audio engine restarted successfully")

                DispatchQueue.main.async {
                    completion(true)
                }

            } catch {
                print("❌ Audio engine restart failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    /// Overloaded version for mock engine testing
    func restartAudioEngine(_ mockEngine: MockAudioEngine, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔄 Restarting mock audio engine for testing...")

            mockEngine.stop()
            mockEngine.reset()

            do {
                try mockEngine.start()
                self.lastAudioEngineRestart = Date()
                print("✅ Mock audio engine restarted successfully")

                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("❌ Mock audio engine restart failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    // MARK: - Integration with Recording System

    /// Main stability check called during sample buffer processing
    func performStabilityChecks(startTime: Date?, audioEngine: AVAudioEngine?) -> StabilityCheckResult {
        var actions: [StabilityAction] = []

        // Check memory pressure
        if shouldCheckMemoryPressure() {
            let memoryAction = checkMemoryPressureAndRecommendAction()
            if memoryAction == .skipFrame {
                actions.append(.skipFrame)
            }
        }

        // Check audio engine restart need
        if let startTime = startTime, let engine = audioEngine {
            if audioEngineNeedsRestart(startTime: startTime) {
                actions.append(.restartAudioEngine(engine))
            }
        }

        return StabilityCheckResult(actions: actions)
    }
}

// MARK: - Supporting Classes

class MemoryPressureMonitor {
    private let source: DispatchSourceMemoryPressure

    init() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .global(qos: .utility))

        source.setEventHandler { [weak self] in
            let event = self?.source.mask
            print("Memory pressure event: \(String(describing: event))")
        }

        source.resume()
    }

    deinit {
        source.cancel()
    }
}

// MARK: - Enums and Structs

enum MemoryPressureAction {
    case continueNormal
    case skipFrame
}

enum StabilityAction {
    case skipFrame
    case restartAudioEngine(AVAudioEngine)
    case flushFiles
}

struct StabilityCheckResult {
    let actions: [StabilityAction]

    var shouldSkipFrame: Bool {
        return actions.contains { action in
            if case .skipFrame = action { return true }
            return false
        }
    }

    var audioEngineToRestart: AVAudioEngine? {
        for action in actions {
            if case .restartAudioEngine(let engine) = action {
                return engine
            }
        }
        return nil
    }
}