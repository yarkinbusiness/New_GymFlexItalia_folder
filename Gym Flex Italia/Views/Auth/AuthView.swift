//
//  AuthView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import AuthenticationServices
import SwiftUI

/// Authentication view with sign in and sign up
struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            AppGradients.background
                .ignoresSafeArea()

            // Floating glow orbs
            ZStack {
                GlowingOrb(color: AppColors.brand, size: 320, offset: CGSize(width: -140, height: -220))
                GlowingOrb(color: AppColors.accent, size: 260, offset: CGSize(width: 160, height: 120))
            }
            .opacity(0.5)

            VStack(spacing: Spacing.xl) {
                Spacer().frame(height: 60)
                authCard
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)

            if viewModel.isLoading {
                LoadingOverlayView()
            }
        }
    }

    private var authCard: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                    .padding()
                    .background(
                        Circle()
                            .fill(AppColors.brand.opacity(0.15))
                    )

                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(AppFonts.h2)
                    .foregroundColor(AppColors.textHigh)

                Text(isSignUp ? "Join GymFlex to unlock premium gyms across Italy." :
                    "Sign in to access your gym sessions")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textDim)
            }
            .frame(maxWidth: .infinity)

            AuthSegmentedControl(isSignUp: $isSignUp)

            VStack(spacing: Spacing.md) {
                if isSignUp {
                    GlassInputField(
                        placeholder: "Full Name",
                        text: $viewModel.fullName,
                        icon: "person.fill",
                        textContentType: .name
                    )
                }

                GlassInputField(
                    placeholder: "Email",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )

                GlassInputField(
                    placeholder: "Password",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    isSecure: true,
                    textContentType: isSignUp ? .newPassword : .password
                )

                if isSignUp {
                    GlassInputField(
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        icon: "lock.rotation",
                        isSecure: true,
                        textContentType: .newPassword
                    )
                } else {
                    Button("Forgot Password?") {
                        Task { await viewModel.resetPassword() }
                    }
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accent)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, Spacing.xs)
                }
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            PrimaryGradientButton(
                title: isSignUp ? "Create Account" : "Sign In",
                isLoading: viewModel.isLoading
            ) {
                Task {
                    if isSignUp {
                        await viewModel.signUp()
                    } else {
                        await viewModel.signIn()
                    }
                }
            }

            DividerRow()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case let .success(authorization):
                    Task { await viewModel.signInWithApple(authorization) }
                case let .failure(error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous))

            HStack(spacing: Spacing.xs) {
                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                    .font(AppFonts.bodySmall)
                    .foregroundColor(AppColors.textDim)
                Button(isSignUp ? "Sign In" : "Sign Up") {
                    withAnimation(.spring(response: 0.4)) {
                        isSignUp.toggle()
                    }
                }
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.accent)
            }
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.xl)
    }
}

// MARK: - Components

// GlassInputField is now in Views/Shared/GlassInputField.swift

private struct PrimaryGradientButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .background(AppGradients.primary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous))
            .shadow(color: AppColors.brand.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .disabled(isLoading)
    }
}

private struct DividerRow: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
            Text("or continue with")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textDim)
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
    }
}

private struct ErrorBanner: View {
    let message: String
    var dismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.danger)

            Text(message)
                .font(AppFonts.bodySmall)
                .foregroundColor(AppColors.textHigh)

            Spacer()

            if let dismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textDim)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous)
                .fill(AppColors.danger.opacity(0.15))
        )
    }
}

private struct AuthSegmentedControl: View {
    @Binding var isSignUp: Bool

    var body: some View {
        HStack(spacing: 4) {
            segmentButton(title: "Sign In", isActive: !isSignUp) {
                withAnimation(.spring(response: 0.3)) { isSignUp = false }
            }
            segmentButton(title: "Sign Up", isActive: isSignUp) {
                withAnimation(.spring(response: 0.3)) { isSignUp = true }
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous)
                .fill(AppColors.card.opacity(0.6))
        )
    }

    private func segmentButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.label)
                .foregroundColor(isActive ? AppColors.textHigh : AppColors.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    Group {
                        if isActive {
                            AppGradients.primary
                        } else {
                            Color.clear
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadii.md, style: .continuous))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct GlowingOrb: View {
    let color: Color
    let size: CGFloat
    let offset: CGSize

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(colors: [
                    color.opacity(0.5),
                    color.opacity(0.15),
                    .clear,
                ], center: .center, startRadius: 0, endRadius: size / 2)
            )
            .frame(width: size, height: size)
            .blur(radius: 60)
            .offset(offset)
            .scaleEffect(animate ? 1.1 : 0.9)
            .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
            .onAppear { animate = true }
    }
}

#Preview {
    AuthView()
        .preferredColorScheme(.dark)
}
