//
//  OwnerModeView.swift
//  Gym Flex Italia
//
//  DEBUG-only Owner Mode for validating user QR codes.
//  Simulates gym owner validation flow without camera.
//

#if DEBUG
import SwiftUI

/// Owner Mode view for QR validation (DEBUG only)
struct OwnerModeView: View {
    
    @StateObject private var viewModel = OwnerModeViewModel()
    @State private var showReportJSON = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                headerSection
                
                // Gym Context
                gymContextSection
                
                // QR Input
                qrInputSection
                
                // Validate Button
                validateButton
                
                // Messages
                messagesSection
                
                // Validation Result
                if viewModel.hasValidationResult {
                    validationResultSection
                }
                
                // Usage Report
                if viewModel.canGenerateReport {
                    usageReportSection
                }
            }
            .padding(Spacing.md)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Owner Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 40))
                .foregroundColor(AppColors.brand)
            
            Text("QR Validation Test")
                .font(AppFonts.h3)
                .foregroundColor(.primary)
            
            Text("Paste a user QR payload to validate (no camera)")
                .font(AppFonts.bodySmall)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.md)
    }
    
    // MARK: - Gym Context
    
    private var gymContextSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Validation Context", systemImage: "building.2")
                .font(AppFonts.label)
                .foregroundColor(.secondary)
            
            Picker("Select Gym", selection: $viewModel.selectedGymId) {
                ForEach(viewModel.allGyms, id: \.id) { gym in
                    Text("\(gym.name)")
                        .tag(gym.id)
                }
            }
            .pickerStyle(.menu)
            .padding(Spacing.sm)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(CornerRadii.md)
            
            Text("QR codes for other gyms will show 'Wrong Gym' error")
                .font(AppFonts.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - QR Input
    
    private var qrInputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("QR Payload", systemImage: "doc.text")
                .font(AppFonts.label)
                .foregroundColor(.secondary)
            
            TextEditor(text: $viewModel.qrInput)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 120)
                .padding(Spacing.sm)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadii.md)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            
            HStack(spacing: Spacing.sm) {
                Button {
                    viewModel.pasteFromClipboard()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(AppFonts.bodySmall)
                }
                .buttonStyle(.bordered)
                
                Button {
                    viewModel.clearInput()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(AppFonts.bodySmall)
                }
                .buttonStyle(.bordered)
                
                Button {
                    viewModel.loadSamplePayload()
                } label: {
                    Label("Load Sample", systemImage: "square.and.arrow.down")
                        .font(AppFonts.bodySmall)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Validate Button
    
    private var validateButton: some View {
        Button {
            Task {
                await viewModel.validate()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.shield")
                }
                Text("Validate QR")
            }
            .font(AppFonts.label)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(AppGradients.primary)
            .cornerRadius(CornerRadii.md)
        }
        .disabled(viewModel.isLoading || viewModel.qrInput.isEmpty)
    }
    
    // MARK: - Messages
    
    private var messagesSection: some View {
        VStack(spacing: Spacing.sm) {
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(AppFonts.bodySmall)
                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(CornerRadii.sm)
            }
            
            if let success = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(success)
                        .font(AppFonts.bodySmall)
                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color.green.opacity(0.15))
                .cornerRadius(CornerRadii.sm)
            }
        }
    }
    
    // MARK: - Validation Result
    
    private var validationResultSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Validation Result", systemImage: "shield")
                .font(AppFonts.label)
                .foregroundColor(.secondary)
            
            if let result = viewModel.validationResult {
                // Status badge
                HStack(spacing: Spacing.sm) {
                    Image(systemName: viewModel.statusIcon)
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.statusColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.status.rawValue.capitalized)
                            .font(AppFonts.h4)
                            .foregroundColor(viewModel.statusColor)
                        
                        Text(result.message)
                            .font(AppFonts.bodySmall)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(Spacing.md)
                .background(viewModel.statusColor.opacity(0.1))
                .cornerRadius(CornerRadii.md)
                
                // Details
                if let payload = viewModel.decodedPayload {
                    VStack(spacing: Spacing.sm) {
                        resultRow("Booking ID", payload.bookingId)
                        resultRow("Gym ID", payload.gymId)
                        resultRow("User ID", payload.userId)
                        resultRow("Reference", payload.referenceCode)
                        resultRow("Session Start", viewModel.formatDate(payload.sessionStart))
                        resultRow("Session End", viewModel.formatDate(payload.sessionEnd))
                        
                        if let remaining = result.remainingMinutes {
                            resultRow("Remaining", "\(remaining) minutes")
                        }
                        
                        resultRow("Checksum Valid", payload.isChecksumValid ? "Yes" : "No")
                    }
                    .padding(Spacing.md)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(CornerRadii.md)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.bodySmall)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Usage Report
    
    private var usageReportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Usage Report Preview", systemImage: "doc.text.fill")
                .font(AppFonts.label)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.generateReportPreview()
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Generate Usage Report")
                }
                .font(AppFonts.bodySmall)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if let report = viewModel.reportPreview {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Report Summary")
                        .font(AppFonts.h5)
                    
                    resultRow("Booking ID", report.bookingId)
                    resultRow("Total Minutes", "\(report.totalMinutesUsed)")
                    resultRow("Total Charged", report.formattedAmount)
                    resultRow("Status", report.status.rawValue.capitalized)
                    resultRow("Check-in", viewModel.formatDate(report.checkInTime))
                    resultRow("Check-out", report.checkOutTime.map { viewModel.formatDate($0) } ?? "Active")
                }
                .padding(Spacing.md)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(CornerRadii.md)
                
                HStack(spacing: Spacing.sm) {
                    Button {
                        showReportJSON.toggle()
                    } label: {
                        Label(showReportJSON ? "Hide JSON" : "Show JSON", systemImage: "chevron.down")
                            .font(AppFonts.bodySmall)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        viewModel.copyReportJSON()
                    } label: {
                        Label("Copy JSON", systemImage: "doc.on.doc")
                            .font(AppFonts.bodySmall)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if showReportJSON {
                    reportJSONView(report)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func reportJSONView(_ report: SessionUsageReport) -> some View {
        Group {
            if let json = encodeReport(report) {
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(json)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(Spacing.sm)
                }
                .frame(maxHeight: 200)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(CornerRadii.sm)
            }
        }
    }
    
    private func encodeReport(_ report: SessionUsageReport) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(report) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

#Preview {
    NavigationStack {
        OwnerModeView()
    }
}
#endif
