//
//  DeepLinkSimulatorView.swift
//  Gym Flex Italia
//
//  Debug view for simulating deep link navigation (demo mode only)
//

import SwiftUI

/// Debug view for testing deep link routing
/// Only accessible in demo mode through Settings
struct DeepLinkSimulatorView: View {
    
    @EnvironmentObject var deepLinkQueue: DeepLinkQueue
    @EnvironmentObject var router: AppRouter
    
    @State private var customTransactionId = "txn_001"
    @State private var showEnqueuedMessage = false
    
    var body: some View {
        Form {
            // Queue Status Section
            Section {
                HStack {
                    Text("Pending Links")
                    Spacer()
                    Text("\(deepLinkQueue.count)")
                        .foregroundColor(deepLinkQueue.hasPending ? .orange : .secondary)
                        .fontWeight(deepLinkQueue.hasPending ? .bold : .regular)
                }
                
                if deepLinkQueue.hasPending {
                    Button("Clear Queue") {
                        DemoTapLogger.log("Debug.DeepLink.ClearQueue")
                        deepLinkQueue.clear()
                    }
                    .foregroundColor(.red)
                }
            } header: {
                Text("Queue Status")
            }
            
            // Simulate Deep Links Section
            Section {
                Button {
                    DemoTapLogger.log("Debug.DeepLink.BookSession")
                    deepLinkQueue.enqueue(.bookSession)
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "calendar.badge.plus",
                        iconColor: .blue,
                        title: "Book Session",
                        subtitle: "Navigate to Discover tab"
                    )
                }
                
                Button {
                    DemoTapLogger.log("Debug.DeepLink.Wallet")
                    deepLinkQueue.enqueue(.wallet)
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "wallet.pass.fill",
                        iconColor: .green,
                        title: "Wallet",
                        subtitle: "Navigate to Wallet screen"
                    )
                }
                
                Button {
                    DemoTapLogger.log("Debug.DeepLink.WalletTransaction", context: "id: \(customTransactionId)")
                    deepLinkQueue.enqueue(.walletTransaction(customTransactionId))
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "doc.text.fill",
                        iconColor: .purple,
                        title: "Wallet Transaction",
                        subtitle: "Navigate to transaction: \(customTransactionId)"
                    )
                }
                
                Button {
                    DemoTapLogger.log("Debug.DeepLink.EditProfile")
                    deepLinkQueue.enqueue(.editProfile)
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "person.crop.circle.badge.plus",
                        iconColor: .orange,
                        title: "Edit Profile",
                        subtitle: "Navigate to Edit Profile screen"
                    )
                }
                
                Button {
                    DemoTapLogger.log("Debug.DeepLink.Settings")
                    deepLinkQueue.enqueue(.settings)
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        title: "Settings",
                        subtitle: "Navigate to Settings screen"
                    )
                }
            } header: {
                Text("Simulate Deep Links")
            } footer: {
                Text("Tap a link to enqueue it. The app will process it and navigate accordingly.")
            }
            
            // Batch Testing Section
            Section {
                Button {
                    DemoTapLogger.log("Debug.DeepLink.BatchTest")
                    // Enqueue multiple deep links to test queue stability
                    deepLinkQueue.enqueue(.wallet)
                    deepLinkQueue.enqueue(.bookSession)
                    deepLinkQueue.enqueue(.settings)
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "rectangle.stack.fill",
                        iconColor: .indigo,
                        title: "Enqueue Multiple Links",
                        subtitle: "Wallet → Book Session → Settings"
                    )
                }
                
                Button {
                    DemoTapLogger.log("Debug.DeepLink.StressTest")
                    // Stress test with same link multiple times
                    for _ in 0..<5 {
                        deepLinkQueue.enqueue(.bookSession)
                    }
                    showEnqueuedFeedback()
                } label: {
                    DeepLinkRow(
                        icon: "bolt.fill",
                        iconColor: .red,
                        title: "Stress Test (5x Book Session)",
                        subtitle: "Test idempotent routing"
                    )
                }
            } header: {
                Text("Batch Testing")
            } footer: {
                Text("Test queue stability with multiple links. Routing should remain stable without stacking duplicates.")
            }
            
            // Transaction ID Configuration
            Section {
                TextField("Transaction ID", text: $customTransactionId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Configuration")
            } footer: {
                Text("Set a custom transaction ID for the Wallet Transaction deep link. Use 'txn_001' through 'txn_015' for mock transactions.")
            }
        }
        .navigationTitle("Deep Link Simulator")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showEnqueuedMessage {
                VStack {
                    Spacer()
                    Text("Deep link enqueued!")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showEnqueuedMessage)
    }
    
    private func showEnqueuedFeedback() {
        showEnqueuedMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showEnqueuedMessage = false
        }
    }
}

// MARK: - Deep Link Row Component

struct DeepLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "arrow.right.circle")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        DeepLinkSimulatorView()
    }
    .environmentObject(DeepLinkQueue())
    .environmentObject(AppRouter())
}

