//
//  DevicesSessionsView.swift
//  Gym Flex Italia
//
//  View for managing device sessions.
//

import SwiftUI

/// Devices and sessions management view
struct DevicesSessionsView: View {
    
    @EnvironmentObject var router: AppRouter
    @ObservedObject var deviceStore = DeviceSessionsStore.shared
    
    @State private var showSignOutConfirmation = false
    @State private var sessionToSignOut: DeviceSession?
    @State private var showSignOutAllConfirmation = false
    
    var body: some View {
        List {
            // Current Device
            if let current = deviceStore.currentSession {
                Section {
                    sessionRow(current)
                } header: {
                    Text("This Device")
                }
            }
            
            // Other Devices
            Section {
                if deviceStore.otherSessions.isEmpty {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.success)
                            
                            Text("No other devices")
                                .font(AppFonts.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.lg)
                        
                        Spacer()
                    }
                } else {
                    ForEach(deviceStore.otherSessions) { session in
                        sessionRow(session)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    sessionToSignOut = session
                                    showSignOutConfirmation = true
                                } label: {
                                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                    }
                }
            } header: {
                Text("Other Devices")
            }
            
            // Sign Out All
            if deviceStore.hasOtherSessions {
                Section {
                    Button(role: .destructive) {
                        showSignOutAllConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            
                            Label("Sign Out of All Other Devices", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(AppColors.danger)
                            
                            Spacer()
                        }
                    }
                } footer: {
                    Text("This will sign you out of all devices except this one.")
                }
            }
        }
        .navigationTitle("Devices & Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Sign Out Device",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                if let session = sessionToSignOut {
                    DemoTapLogger.log("Security.SignOutDevice", context: session.deviceName)
                    deviceStore.signOut(sessionId: session.id)
                }
                sessionToSignOut = nil
            }
            Button("Cancel", role: .cancel) {
                sessionToSignOut = nil
            }
        } message: {
            if let session = sessionToSignOut {
                Text("Sign out of \(session.deviceName)?")
            }
        }
        .confirmationDialog(
            "Sign Out All Other Devices",
            isPresented: $showSignOutAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out All", role: .destructive) {
                DemoTapLogger.log("Security.SignOutAllOtherDevices")
                deviceStore.signOutAllOtherSessions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will sign you out of all other devices. You'll remain signed in on this device.")
        }
    }
    
    // MARK: - Session Row
    
    private func sessionRow(_ session: DeviceSession) -> some View {
        HStack(spacing: Spacing.md) {
            // Device Icon
            ZStack {
                Circle()
                    .fill(session.isCurrentDevice ? AppColors.success.opacity(0.2) : Color(.tertiarySystemFill))
                    .frame(width: 44, height: 44)
                
                Image(systemName: session.platformIcon)
                    .font(.system(size: 18))
                    .foregroundColor(session.isCurrentDevice ? AppColors.success : .secondary)
            }
            
            // Device Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Spacing.sm) {
                    Text(session.deviceName)
                        .font(AppFonts.body)
                        .foregroundColor(.primary)
                    
                    if session.isCurrentDevice {
                        Text("This device")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.success.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: Spacing.sm) {
                    Text(session.lastActiveFormatted)
                        .font(AppFonts.caption)
                        .foregroundColor(.secondary)
                    
                    if let location = session.location {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(location)
                            .font(AppFonts.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        DevicesSessionsView()
    }
    .environmentObject(AppRouter())
}
