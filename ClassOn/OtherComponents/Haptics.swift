//
//  Haptis.swift
//  SuperLearn
//
//  Created by Thomas B on 4/29/25.
//

import CoreHaptics
import UIKit

final class HapticsManager {
    static let shared = HapticsManager() // Singleton instance

    private var hapticEngine: CHHapticEngine?

    private init() {
        prepareHaptics() // Automatically prepare when initialized
    }

    public func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device does not support haptics.")
            return
        }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("Haptic engine successfully started.")
        } catch {
            print("Haptic engine creation error: \(error.localizedDescription)")
        }
    }

    public func playHapticFeedback(
        intensity: Float = 0.8,        // Default intensity
        sharpness: Float = 0.8,        // Default sharpness
        duration: TimeInterval = 0.1,  // Default duration for continuous haptic
        startTime: TimeInterval = 0,   // Default start time (immediate)
        eventType: CHHapticEvent.EventType = .hapticTransient // Default to transient
    ) {
        guard let engine = hapticEngine else {
            print("Haptic engine not initialized, preparing now.")
            prepareHaptics() // Try re-initializing
            return
        }

        var events = [CHHapticEvent]()

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

        let event = CHHapticEvent(
            eventType: eventType,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: startTime,
            duration: eventType == .hapticContinuous ? duration : 0
        )

        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic feedback: \(error.localizedDescription)")
            prepareHaptics() // Restart haptic engine if there's an error
        }
    }

    public func playContinuousHapticFeedback(
        intensity: Float = 1.0,        // Default intensity for continuous feedback
        sharpness: Float = 0.7,        // Default sharpness for continuous feedback
        duration: TimeInterval = 1.0,  // Duration of continuous feedback
        startTime: TimeInterval = 0    // Default start time (immediate)
    ) {
        playHapticFeedback(
            intensity: intensity,
            sharpness: sharpness,
            duration: duration,
            startTime: startTime,
            eventType: .hapticContinuous
        )
    }

    public func playWordFormationHaptic(for word: String) {
        let delayPerLetter: TimeInterval = 0.05  // Adjust this value as needed
        for (index, _) in word.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayPerLetter * Double(index)) {
                self.playHapticFeedback(
                    intensity: 0.5,
                    sharpness: 0.5,
                    eventType: .hapticTransient
                )
            }
        }
    }
    
    // Additional method to trigger feedback with a higher impact for stronger feedback
    public func playStrongFeedback() {
        playHapticFeedback(intensity: 1.0, sharpness: 1.0, eventType: .hapticTransient)
    }

    // Additional method to trigger feedback with a more subtle effect
    public func playSubtleFeedback() {
        playHapticFeedback(intensity: 0.3, sharpness: 0.4, eventType: .hapticTransient)
    }
}
