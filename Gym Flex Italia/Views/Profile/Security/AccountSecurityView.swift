//
//  AccountSecurityView.swift
//  Gym Flex Italia
//
//  Main view for account and security settings.
//

import SwiftUI

/// Account and security settings view
struct AccountSecurityView: View {
    
    @EnvironmentObject var router: AppRouter
    @ObservedObject var securityStore = SecuritySettingsStore.shared
    @ObservedObject var deviceStore = DeviceSessionsStore.shared
    
    var body: some View {
        List {
            // Password Section
            passwordSection
            
            // Biometric Section
            biometricSection
            
            // Two-Factor Section
            twoFactorSection
            
            // Devices Section
            devicesSection
            
            // Danger Zone
            dangerZoneSection
        }
        .navigationTitle("Account & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Password Section
    
    private var passwordSection: some View {
        Section {
            Button {
                DemoTapLogger.log("Security.ChangePassword")
                router.pushChangePassword()
            } label: {
                HStack {
                    Label("Change Password", systemImage: "key.fill")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let formatted = securityStore.lastPasswordChangeFormatted {
                        Text(formatted)
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Sign-in & Password")
        }
    }
    
    // MARK: - Biometric Section
    
    private var biometricSection: some View {
        Section {
            if let biometricType = BiometricAvailability.supportedType() {
                Toggle(isOn: $securityStore.biometricLockEnabled) {
                    Label("Enable \(biometricType)", systemImage: BiometricAvailability.iconName)
                }
                .onChange(of: securityStore.biometricLockEnabled) { _, enabled in
                    DemoTapLogger.log("Security.BiometricLock", context: "enabled: \(enabled)")
                    if !enabled {
                        securityStore.requireBiometricOnLaunch = false
                    }
                }
                
                Toggle(isOn: $securityStore.requireBiometricOnLaunch) {
                    Label("Require on App Launch", systemImage: "lock.shield")
                }
                .disabled(!securityStore.biometricLockEnabled)
                .onChange(of: securityStore.requireBiometricOnLaunch) { _, enabled in
                    DemoTapLogger.log("Security.RequireOnLaunch", context: "enabled: \(enabled)")
                }
            } else {
                HStack {
                    Label("Biometric Lock", systemImage: "faceid")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Not available")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Biometric Security")
        } footer: {
            if BiometricAvailability.supportedType() != nil {
                Text("Use biometrics to unlock the app and access sensitive features.")
            } else {
                Text("This device does not support biometric authentication.")
            }
        }
    }
    
    // MARK: - Two-Factor Section
    
    private var twoFactorSection: some View {
        Section {
            Toggle(isOn: $securityStore.twoFactorEnabled) {
                Label("Two-Factor Authentication", systemImage: "shield.checkered")
            }
            .onChange(of: securityStore.twoFactorEnabled) { _, enabled in
                DemoTapLogger.log("Security.TwoFactor", context: "enabled: \(enabled)")
            }
        } header: {
            Text("Additional Security")
        } footer: {
            Text("Two-factor authentication adds an extra layer of security to your account.")
        }
    }
    
    // MARK: - Devices Section
    
    private var devicesSection: some View {
        Section {
            Button {
                DemoTapLogger.log("Security.DevicesSessions")
                router.pushDevicesSessions()
            } label: {
                HStack {
                    Label("Devices & Sessions", systemImage: "iphone")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(deviceStore.sessions.count) device\(deviceStore.sessions.count == 1 ? "" : "s")")
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Active Sessions")
        }
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        Section {
            Button {
                DemoTapLogger.log("Security.DeleteAccount")
                router.pushDeleteAccount()
            } label: {
                HStack {
                    Label("Delete Account", systemImage: "trash.fill")
                        .foregroundColor(AppColors.danger)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Permanently delete your account and all associated data. This cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AccountSecurityView()
    }
    .environmentObject(AppRouter())
}
