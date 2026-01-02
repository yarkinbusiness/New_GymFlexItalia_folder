//
//  HelpSupportView.swift
//  Gym Flex Italia
//
//  Help & Support hub view.
//

import SwiftUI
import MessageUI

/// Help & Support hub view
struct HelpSupportView: View {
    
    @EnvironmentObject var router: AppRouter
    
    @State private var showMailUnavailableAlert = false
    @State private var showMailComposer = false
    @State private var mailSubject = "GymFlex Support"
    
    var body: some View {
        List {
            // Help Section
            helpSection
            
            // Contact Section
            contactSection
            
            // Legal Section
            legalSection
            
            // App Info Section
            appInfoSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mail Not Available", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mail is not configured on this device. Please email support@gymflex.com directly.")
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: mailSubject,
                body: mailBody(),
                recipients: ["support@gymflex.com"]
            )
        }
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        Section {
            // FAQ
            Button {
                DemoTapLogger.log("HelpSupport.FAQ")
                router.pushFAQ()
            } label: {
                HStack {
                    Label("FAQ", systemImage: "questionmark.circle")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Help")
        }
    }
    
    // MARK: - Contact Section
    
    private var contactSection: some View {
        Section {
            // Contact Support
            Button {
                DemoTapLogger.log("HelpSupport.ContactSupport")
                mailSubject = "GymFlex Support"
                openMail()
            } label: {
                Label("Contact Support", systemImage: "envelope")
                    .foregroundColor(.primary)
            }
            
            // Report a Bug
            Button {
                DemoTapLogger.log("HelpSupport.ReportBug")
                router.pushReportBug()
            } label: {
                HStack {
                    Label("Report a Bug", systemImage: "ladybug")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Contact")
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        Section {
            // Terms of Service
            Button {
                DemoTapLogger.log("HelpSupport.Terms")
                router.pushTerms()
            } label: {
                HStack {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Privacy Policy
            Button {
                DemoTapLogger.log("HelpSupport.Privacy")
                router.pushPrivacy()
            } label: {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Legal")
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(AppDiagnostics.appVersionString())
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(AppDiagnostics.buildNumberString())
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Environment")
                Spacer()
                Text(AppDiagnostics.environmentString())
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("App Info")
        } footer: {
            Text("© 2026 GymFlex Italia. All rights reserved.")
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.md)
        }
    }
    
    // MARK: - Helpers
    
    private func openMail() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback to mailto URL
            let mailtoString = "mailto:support@gymflex.com?subject=\(mailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(mailBody().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if let url = URL(string: mailtoString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showMailUnavailableAlert = true
            }
        }
    }
    
    private func mailBody() -> String {
        """
        Hi GymFlex Support,
        
        [Please describe your issue or question here]
        
        \(AppDiagnostics.diagnosticsSummary())
        """
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipients: [String]
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.setToRecipients(recipients)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        HelpSupportView()
    }
    .environmentObject(AppRouter())
}
