//
//  ToastBanner.swift
//  Gym Flex Italia
//
//  Lightweight toast/banner overlay for success/info messages.
//

import SwiftUI

/// A lightweight toast banner that appears at the bottom of the screen
struct ToastBanner: View {
    
    let message: String
    var icon: String = "checkmark.circle.fill"
    var iconColor: Color = AppColors.success
    var duration: TimeInterval = 2.0
    
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(message)
                    .font(AppFonts.body)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// View modifier for showing a toast banner
struct ToastModifier: ViewModifier {
    
    let message: String
    var icon: String = "checkmark.circle.fill"
    var iconColor: Color = AppColors.success
    var duration: TimeInterval = 2.0
    
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                ToastBanner(
                    message: message,
                    icon: icon,
                    iconColor: iconColor,
                    duration: duration,
                    isPresented: $isPresented
                )
                .padding(.bottom, 100) // Above tab bar
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        }
    }
}

extension View {
    /// Displays a toast banner when isPresented is true
    func toast(
        _ message: String,
        icon: String = "checkmark.circle.fill",
        iconColor: Color = AppColors.success,
        duration: TimeInterval = 2.0,
        isPresented: Binding<Bool>
    ) -> some View {
        modifier(ToastModifier(
            message: message,
            icon: icon,
            iconColor: iconColor,
            duration: duration,
            isPresented: isPresented
        ))
    }
}

#Preview {
    VStack {
        Text("Content behind toast")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toast("Joined group!", isPresented: .constant(true))
}
