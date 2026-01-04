//
//  NavigationMicroShift.swift
//  Gym Flex Italia
//
//  View modifier that adds a subtle horizontal micro-shift animation
//  when destination views appear via programmatic navigation.
//

import SwiftUI
import UIKit

/// A view modifier that applies a subtle horizontal micro-shift animation
/// when a destination view appears via navigation push or pop.
///
/// Usage:
/// ```
/// SomeDestinationView()
///     .modifier(NavigationMicroShift(lastNavAction: router.lastNavAction))
/// ```
///
/// Respects Reduce Motion accessibility setting.
struct NavigationMicroShift: ViewModifier {
    
    /// The last navigation action (push/pop/reset) from AppRouter
    let lastNavAction: NavAction
    
    /// Current horizontal offset for the micro-shift animation
    @State private var offsetX: CGFloat = 0
    
    /// Whether this is the first appearance (to set initial offset)
    @State private var hasAppeared = false
    
    /// Returns the initial offset based on navigation direction
    private var initialOffset: CGFloat {
        switch lastNavAction {
        case .push:
            // New screen slides in from right
            return GFMotion.NavigationMotion.microShiftOffset
        case .pop:
            // Revealed screen slides in from left
            return -GFMotion.NavigationMotion.microShiftOffset
        case .reset:
            // No shift on reset to root
            return 0
        }
    }
    
    /// Whether to skip animation (Reduce Motion enabled)
    private var shouldReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                
                // Skip animation if Reduce Motion is enabled
                guard !shouldReduceMotion else { return }
                
                // Set initial offset without animation
                offsetX = initialOffset
                
                // Animate to neutral position
                withAnimation(GFMotion.navigation) {
                    offsetX = 0
                }
            }
    }
}

// MARK: - View Extension for Convenience

extension View {
    /// Applies the navigation micro-shift effect for page transitions.
    /// 
    /// - Parameter lastNavAction: The last navigation action from AppRouter
    /// - Returns: A view with the micro-shift effect applied
    func navigationMicroShift(lastNavAction: NavAction) -> some View {
        modifier(NavigationMicroShift(lastNavAction: lastNavAction))
    }
}
