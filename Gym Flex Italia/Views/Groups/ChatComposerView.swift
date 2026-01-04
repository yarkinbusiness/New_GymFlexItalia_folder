//
//  ChatComposerView.swift
//  Gym Flex Italia
//
//  Chat input composer with voice dictation support.
//  Features: expanding dark mode when listening, waveform visualizer,
//  morphing send/checkmark button, cancel button.
//

import SwiftUI
import UIKit

/// Chat composer with integrated voice dictation
struct ChatComposerView: View {
    
    /// Binding to the message text
    @Binding var messageText: String
    
    /// Whether a message is currently being sent
    let isSending: Bool
    
    /// Called when user taps send
    let onSend: () -> Void
    
    /// Voice dictation controller
    @StateObject private var dictation = VoiceDictationController()
    
    /// Scene phase for lifecycle handling
    @Environment(\.scenePhase) private var scenePhase
    
    /// Animation namespace for matched geometry
    @Namespace private var composerNamespace
    
    /// Whether Reduce Motion is enabled
    private var shouldReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Whether dictation is active
    private var isListening: Bool {
        dictation.state == .listening
    }
    
    /// Animation for the expanding background
    private var expandAnimation: Animation? {
        shouldReduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.75)
    }
    
    /// Animation for button morphs
    private var morphAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Listening label (above composer when active)
            if isListening {
                listeningLabel
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Main composer bar
            composerBar
        }
        .background(isListening ? Color.black : Color(.systemBackground))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(isListening ? Color.clear : Color(.separator))
                .frame(height: 0.5)
        }
        .animation(morphAnimation, value: isListening)
        .onChange(of: scenePhase) { _, newPhase in
            // Stop dictation when app goes to background or becomes inactive
            if newPhase != .active {
                dictation.forceStopDueToLifecycle()
            }
        }
    }
    
    // MARK: - Listening Label
    
    private var listeningLabel: some View {
        HStack {
            Text("Listening…")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.xs)
        .background(Color.black) // Ensure black background in light mode
    }
    
    // MARK: - Composer Bar
    
    private var composerBar: some View {
        ZStack {
            // Expanding dark background
            if isListening {
                expandingBackground
            }
            
            // Content
            HStack(spacing: Spacing.sm) {
                // Cancel button slot (always reserved to prevent layout shift)
                cancelButtonSlot
                
                // Input area
                inputArea
                
                // Dictation button (only when not listening)
                if !isListening {
                    dictationButton
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Send / Checkmark button
                actionButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }
    
    // MARK: - Expanding Background
    
    private var expandingBackground: some View {
        GeometryReader { geometry in
            ZStack {
                if shouldReduceMotion {
                    // Simple fade for Reduce Motion
                    Color.black
                        .transition(.opacity)
                } else {
                    // Expanding circle effect
                    Circle()
                        .fill(Color.black)
                        .frame(width: geometry.size.width * 3, height: geometry.size.width * 3)
                        .offset(x: geometry.size.width * 0.3, y: 0)
                        .transition(.scale(scale: 0.01, anchor: .trailing))
                }
            }
        }
        .clipped()
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        ZStack {
            if isListening {
                // Listening mode: show transcript and waveform
                listeningInputView
            } else {
                // Normal mode: text field
                normalInputView
            }
        }
        .frame(minHeight: 36)
        .background(
            RoundedRectangle(cornerRadius: CornerRadii.lg)
                .fill(isListening ? Color.white.opacity(0.1) : Color(.secondarySystemBackground))
        )
    }
    
    private var normalInputView: some View {
        TextField("Type a message...", text: $messageText)
            .font(AppFonts.body)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
    }
    
    private var listeningInputView: some View {
        HStack(spacing: Spacing.md) {
            // Transcript or placeholder
            Text(dictation.transcript.isEmpty ? "Speak now..." : dictation.transcript)
                .font(AppFonts.body)
                .foregroundColor(dictation.transcript.isEmpty ? .white.opacity(0.5) : .white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Waveform visualizer
            WaveformView(
                level: dictation.waveformLevel,
                barCount: 8,
                maxHeight: 20,
                barWidth: 2.5,
                spacing: 2,
                color: .white
            )
            .frame(width: 44)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
    
    // MARK: - Dictation Button
    
    private var dictationButton: some View {
        Button {
            DemoTapLogger.log("Chat.Dictation.Start")
            withAnimation(expandAnimation) {
                dictation.startListening()
            }
        } label: {
            Image(systemName: "mic.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(.secondaryLabel))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Start dictation")
    }
    
    // MARK: - Cancel Button Slot (always reserves space)
    
    /// Fixed-width container that always reserves space for cancel button
    /// Prevents layout shift when toggling dictation state
    private var cancelButtonSlot: some View {
        ZStack {
            if isListening {
                // Active cancel button
                cancelButton
                    .opacity(1)
                    .scaleEffect(shouldReduceMotion ? 1 : 1)
            } else {
                // Invisible placeholder (same size, not tappable)
                Color.clear
            }
        }
        .frame(width: 44, height: 44)
        .animation(shouldReduceMotion ? .none : .easeInOut(duration: 0.2), value: isListening)
    }
    
    // MARK: - Cancel Button
    
    private var cancelButton: some View {
        Button {
            DemoTapLogger.log("Chat.Dictation.Cancel")
            withAnimation(expandAnimation) {
                dictation.cancel()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .accessibilityLabel("Cancel dictation")
        .accessibilityHint("Stops listening and discards dictated text")
    }
    
    // MARK: - Action Button (Send / Checkmark)
    
    private var actionButton: some View {
        Button {
            if isListening {
                // Commit dictated text
                DemoTapLogger.log("Chat.Dictation.Commit")
                commitDictation()
            } else {
                // Send message
                DemoTapLogger.log("Chat.Message.Send")
                onSend()
            }
        } label: {
            ZStack {
                // Purple circular background (always purple)
                Circle()
                    .fill(buttonBackgroundColor)
                    .frame(width: 40, height: 40)
                
                // Icon with rotation
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isListening ? "checkmark" : "paperplane.fill")
                        .font(.system(size: 16, weight: isListening ? .bold : .regular))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isListening ? 0 : 0))
                        .animation(morphAnimation, value: isListening)
                }
            }
        }
        .disabled(isButtonDisabled)
        .accessibilityLabel(isListening ? "Commit dictation" : "Send message")
    }
    
    /// Button background color
    private var buttonBackgroundColor: Color {
        if isListening {
            // Always purple when listening (checkmark mode)
            return AppColors.brand
        } else {
            // Gray when disabled, purple when enabled
            return messageText.isEmpty ? Color.gray.opacity(0.3) : AppColors.brand
        }
    }
    
    /// Whether the action button is disabled
    private var isButtonDisabled: Bool {
        if isListening {
            // Never disable checkmark - always allow committing
            return false
        } else {
            // Disable send if empty or already sending
            return messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
        }
    }
    
    // MARK: - Actions
    
    /// Commits dictated transcript to the message text
    private func commitDictation() {
        let transcript = dictation.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        withAnimation(expandAnimation) {
            dictation.commit()
        }
        
        guard !transcript.isEmpty else { return }
        
        // Append or replace based on existing text
        if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messageText = transcript
        } else {
            messageText += " " + transcript
        }
    }
}

// MARK: - Preview

#Preview("Normal State") {
    VStack {
        Spacer()
        ChatComposerView(
            messageText: .constant(""),
            isSending: false,
            onSend: {}
        )
    }
    .background(Color(.systemBackground))
}

#Preview("With Text") {
    VStack {
        Spacer()
        ChatComposerView(
            messageText: .constant("Hello world!"),
            isSending: false,
            onSend: {}
        )
    }
    .background(Color(.systemBackground))
}
