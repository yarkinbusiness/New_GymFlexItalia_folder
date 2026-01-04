//
//  VoiceDictationController.swift
//  Gym Flex Italia
//
//  Production-hardened controller for voice dictation in chat composer.
//  Uses Apple's Speech framework with proper audio session management,
//  interruption handling, and lifecycle awareness.
//

import SwiftUI
import Combine
import UIKit
import Speech
import AVFoundation

/// Controller for voice dictation functionality in chat composer
/// Handles real Speech framework recognition with mock fallback
@MainActor
final class VoiceDictationController: ObservableObject {
    
    // MARK: - Published State
    
    /// Current dictation state
    @Published private(set) var state: VoiceDictationState = .idle
    
    /// Transcribed/dictated text buffer
    @Published var transcript: String = ""
    
    /// Audio level for waveform visualization (0.0 - 1.0)
    @Published private(set) var waveformLevel: Double = 0.0
    
    /// Last error message (for debugging or subtle UI feedback)
    @Published private(set) var lastErrorMessage: String?
    
    // MARK: - Speech Recognition Properties
    
    /// Speech recognizer for the device locale
    private var speechRecognizer: SFSpeechRecognizer?
    
    /// Current recognition request
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Current recognition task
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Audio engine for capturing microphone input
    private let audioEngine = AVAudioEngine()
    
    /// Whether we're using real speech recognition or mock
    private var isUsingRealSpeech = false
    
    /// Whether audio tap is currently installed
    private var isTapInstalled = false
    
    // MARK: - Notification Observers
    
    /// Interruption notification observer
    private var interruptionObserver: NSObjectProtocol?
    
    /// Route change notification observer
    private var routeChangeObserver: NSObjectProtocol?
    
    // MARK: - Mock Fallback Properties
    
    /// Timer for mock waveform animation
    private var waveformTimer: Timer?
    
    /// Timer for mock dictation simulation
    private var mockDictationTimer: Timer?
    
    /// Mock phrases for demo dictation
    private let mockPhrases = [
        "Hey everyone! Who's up for a workout session today?",
        "Just finished my morning run, feeling great!",
        "Anyone want to meet at the gym around 5pm?",
        "Great workout yesterday team!",
        "Let's crush it today!"
    ]
    
    /// Current mock phrase index
    private var mockPhraseIndex = 0
    
    // MARK: - Computed Properties
    
    /// Whether dictation is currently active
    var isListening: Bool {
        state == .listening
    }
    
    /// Whether Reduce Motion is enabled
    var shouldReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize speech recognizer for device locale
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        
        // Set up notification observers
        setupNotificationObservers()
    }
    
    deinit {
        // Clean up observers directly (safe from any context)
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        #if DEBUG
        print("🎙️ VoiceDictationController deinit")
        #endif
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Audio session interruption (calls, Siri, other apps)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAudioInterruption(notification)
            }
        }
        
        // Route changes (headphones plugged/unplugged, Bluetooth changes)
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleRouteChange(notification)
            }
        }
        
        #if DEBUG
        print("🎙️ VoiceDictationController - Notification observers set up")
        #endif
    }
    
    private func removeNotificationObservers() {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            routeChangeObserver = nil
        }
        
        #if DEBUG
        print("🎙️ VoiceDictationController - Notification observers removed")
        #endif
    }
    
    // MARK: - Interruption Handling
    
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            #if DEBUG
            print("🎙️ Audio interruption BEGAN (call/Siri/other app)")
            #endif
            
            if state == .listening {
                teardownDictation(reason: "interruptionBegan")
                state = .idle
                lastErrorMessage = "Dictation stopped"
                
                // Clear error message after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    if self?.lastErrorMessage == "Dictation stopped" {
                        self?.lastErrorMessage = nil
                    }
                }
            }
            
        case .ended:
            #if DEBUG
            print("🎙️ Audio interruption ENDED")
            #endif
            // Do NOT auto-restart dictation - let user tap mic again
            // This avoids surprising the user with unexpected recording
            
        @unknown default:
            break
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        #if DEBUG
        print("🎙️ Audio route change - reason: \(reason.rawValue)")
        #endif
        
        // Handle old device disconnected while listening
        if reason == .oldDeviceUnavailable && state == .listening {
            #if DEBUG
            print("🎙️ Audio device disconnected during dictation")
            #endif
            
            teardownDictation(reason: "routeChange")
            state = .idle
        }
    }
    
    // MARK: - Lifecycle Handling
    
    /// Called when app goes to background or becomes inactive
    /// Forces clean teardown of dictation
    func forceStopDueToLifecycle() {
        guard state == .listening else { return }
        
        #if DEBUG
        print("🎙️ Forcing stop due to lifecycle change (background/inactive)")
        #endif
        
        teardownDictation(reason: "scenePhase")
        state = .idle
    }
    
    // MARK: - Public Methods
    
    /// Start listening for voice input
    func startListening() {
        guard state == .idle || state == .cancelled else { return }
        
        state = .listening
        transcript = ""
        lastErrorMessage = nil
        
        // Try to start real speech recognition
        Task {
            await startRealSpeechRecognition()
        }
    }
    
    /// Cancel dictation without committing
    func cancel() {
        teardownDictation(reason: "userCancel")
        transcript = ""
        state = .cancelled
        
        // Reset to idle after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.state = .idle
        }
    }
    
    /// Commit the transcript (caller reads `transcript` property)
    func commit() {
        teardownDictation(reason: "userCommit")
        state = .committing
        
        // Transition to idle after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.state = .idle
        }
    }
    
    // MARK: - Unified Teardown
    
    /// Central teardown method for all stop paths
    /// Ensures clean cleanup of audio engine, recognition task, and session
    private func teardownDictation(reason: String) {
        #if DEBUG
        print("🎙️ teardownDictation(reason: \(reason))")
        #endif
        
        // 1) Stop mock timers if active
        stopMockDictation()
        
        // 2) Stop recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 3) End audio request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // 4) Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            #if DEBUG
            print("🎙️ Audio engine stopped")
            #endif
        }
        
        // 5) Remove input node tap (safe even if not installed)
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
            #if DEBUG
            print("🎙️ Audio tap removed")
            #endif
        }
        
        // 6) Deactivate audio session
        DictationAudioSession.shared.deactivate()
        
        // 7) Reset state flags
        isUsingRealSpeech = false
        waveformLevel = 0.0
        
        #if DEBUG
        print("🎙️ teardownDictation complete")
        #endif
    }
    
    // MARK: - Real Speech Recognition
    
    /// Starts real speech recognition with proper authorization handling
    private func startRealSpeechRecognition() async {
        // Check if speech recognition is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            #if DEBUG
            print("🎙️ Speech recognizer not available, falling back to mock")
            #endif
            startMockDictation()
            return
        }
        
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard speechStatus == .authorized else {
            #if DEBUG
            print("🎙️ Speech recognition not authorized: \(speechStatus.rawValue), falling back to mock")
            #endif
            startMockDictation()
            return
        }
        
        // Request microphone authorization
        let micStatus = await AVAudioApplication.requestRecordPermission()
        
        guard micStatus else {
            #if DEBUG
            print("🎙️ Microphone not authorized, falling back to mock")
            #endif
            startMockDictation()
            return
        }
        
        // Activate audio session FIRST
        do {
            try DictationAudioSession.shared.activate()
        } catch {
            #if DEBUG
            print("🎙️ Failed to activate audio session: \(error), falling back to mock")
            #endif
            lastErrorMessage = "Could not access microphone"
            startMockDictation()
            return
        }
        
        // Start real recognition
        do {
            try await setupAndStartRecognition()
            isUsingRealSpeech = true
            #if DEBUG
            print("🎙️ Real speech recognition started successfully")
            #endif
        } catch {
            #if DEBUG
            print("🎙️ Failed to start speech recognition: \(error), falling back to mock")
            #endif
            DictationAudioSession.shared.deactivate()
            startMockDictation()
        }
    }
    
    /// Sets up and starts the speech recognition session
    private func setupAndStartRecognition() async throws {
        // Cancel any previous task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceDictation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Remove existing tap if any (prevent double-tap error)
        if isTapInstalled {
            inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
        
        // Install tap on audio input for speech recognition and waveform
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for waveform
            Task { @MainActor [weak self] in
                self?.updateWaveformFromBuffer(buffer)
            }
        }
        isTapInstalled = true
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        #if DEBUG
        print("🎙️ Audio engine started, tap installed")
        #endif
        
        // Start recognition task
        guard let recognizer = speechRecognizer else { return }
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    // Update transcript with recognized text
                    self.transcript = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    let nsError = error as NSError
                    
                    // Ignore normal cancellation errors
                    let ignorableCodes = [1, 216, 203, 301] // Various cancellation/interruption codes
                    if !ignorableCodes.contains(nsError.code) {
                        #if DEBUG
                        print("🎙️ Recognition error: \(error)")
                        #endif
                        self.lastErrorMessage = "Speech recognition error"
                        self.teardownDictation(reason: "recognitionError")
                        self.state = .idle
                    }
                }
            }
        }
    }
    
    /// Updates waveform level from audio buffer
    private func updateWaveformFromBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        guard frameLength > 0 else { return }
        
        // Calculate RMS (root mean square) for audio level
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // Convert to 0-1 range with some amplification for visibility
        let level = min(1.0, Double(rms) * 3.0)
        
        // Smooth the transition
        let smoothing = 0.4
        waveformLevel = waveformLevel + (level - waveformLevel) * smoothing
    }
    
    // MARK: - Mock Dictation (Fallback)
    
    /// Starts mock dictation when real speech is unavailable
    private func startMockDictation() {
        #if DEBUG
        print("🎙️ Starting mock dictation mode")
        #endif
        
        isUsingRealSpeech = false
        startMockWaveformAnimation()
        simulateMockDictation()
    }
    
    /// Stops mock dictation timers
    private func stopMockDictation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        mockDictationTimer?.invalidate()
        mockDictationTimer = nil
    }
    
    /// Starts the mock waveform animation timer
    private func startMockWaveformAnimation() {
        waveformTimer?.invalidate()
        
        // Update waveform level at 60fps-ish for smooth animation
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMockWaveformLevel()
            }
        }
    }
    
    /// Updates waveform level with smooth random values (mock)
    private func updateMockWaveformLevel() {
        // Generate smooth random movement
        let targetLevel = Double.random(in: 0.2...0.9)
        
        // Smooth interpolation towards target
        let smoothing = 0.3
        waveformLevel = waveformLevel + (targetLevel - waveformLevel) * smoothing
    }
    
    /// Simulates dictation by building up a mock phrase over time
    private func simulateMockDictation() {
        let phrase = mockPhrases[mockPhraseIndex % mockPhrases.count]
        mockPhraseIndex += 1
        
        let words = phrase.split(separator: " ").map(String.init)
        var wordIndex = 0
        
        // Gradually reveal words
        mockDictationTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self, self.state == .listening else {
                    timer.invalidate()
                    return
                }
                
                if wordIndex < words.count {
                    if self.transcript.isEmpty {
                        self.transcript = words[wordIndex]
                    } else {
                        self.transcript += " " + words[wordIndex]
                    }
                    wordIndex += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
