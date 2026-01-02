//
//  ReportBugView.swift
//  Gym Flex Italia
//
//  View for reporting bugs with diagnostics.
//

import SwiftUI
import MessageUI

/// Report a bug view
struct ReportBugView: View {
    
    @State private var showCopiedToast = false
    @State private var showMailUnavailableAlert = false
    @State private var showMailComposer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.warning.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.warning)
                }
                .padding(.top, Spacing.xl)
                
                // Title
                Text("Report a Bug")
                    .font(AppFonts.h2)
                    .foregroundColor(.primary)
                
                // Explanation
                Text("Found something that's not working right? We'd love to hear about it so we can fix it.")
                    .font(AppFonts.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                
                // Instructions
                VStack(alignment: .leading, spacing: Spacing.md) {
                    instructionRow(number: 1, text: "Describe what happened and what you expected")
                    instructionRow(number: 2, text: "Include steps to reproduce the issue")
                    instructionRow(number: 3, text: "Attach the diagnostics below to help us investigate")
                }
                .padding(Spacing.lg)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.lg)
                .padding(.horizontal, Spacing.md)
                
                // Action Buttons
                VStack(spacing: Spacing.md) {
                    // Copy Diagnostics
                    Button {
                        DemoTapLogger.log("ReportBug.CopyDiagnostics")
                        copyDiagnostics()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Diagnostics")
                        }
                        .font(AppFonts.label)
                        .foregroundColor(AppColors.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppColors.brand.opacity(0.15))
                        .cornerRadius(CornerRadii.md)
                    }
                    
                    // Email Support
                    Button {
                        DemoTapLogger.log("ReportBug.EmailSupport")
                        openMail()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Email Support")
                        }
                        .font(AppFonts.label)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(AppGradients.primary)
                        .cornerRadius(CornerRadii.md)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                
                #if DEBUG
                // Debug: Show diagnostics
                debugDiagnosticsSection
                #endif
                
                Spacer(minLength: Spacing.xl)
            }
        }
        .navigationTitle("Report a Bug")
        .navigationBarTitleDisplayMode(.inline)
        .toast("Diagnostics copied!", isPresented: $showCopiedToast)
        .alert("Mail Not Available", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Mail is not configured on this device. Please email support@gymflex.com directly with the copied diagnostics.")
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: "GymFlex Bug Report",
                body: mailBody(),
                recipients: ["support@gymflex.com"]
            )
        }
    }
    
    // MARK: - Instruction Row
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.brand)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(AppFonts.caption)
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(AppFonts.body)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugDiagnosticsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Diagnostics Preview")
                .font(AppFonts.h5)
                .foregroundColor(.primary)
            
            Text(AppDiagnostics.diagnosticsSummary())
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(Spacing.md)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(CornerRadii.sm)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    #endif
    
    // MARK: - Actions
    
    private func copyDiagnostics() {
        UIPasteboard.general.string = AppDiagnostics.diagnosticsSummary()
        showCopiedToast = true
    }
    
    private func openMail() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Fallback to mailto URL
            let subject = "GymFlex Bug Report"
            let body = mailBody()
            let mailtoString = "mailto:support@gymflex.com?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
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
        
        I found a bug:
        
        **What happened:**
        [Describe the issue]
        
        **What I expected:**
        [Describe expected behavior]
        
        **Steps to reproduce:**
        1. 
        2. 
        3. 
        
        \(AppDiagnostics.diagnosticsSummary())
        """
    }
}

#Preview {
    NavigationStack {
        ReportBugView()
    }
}
