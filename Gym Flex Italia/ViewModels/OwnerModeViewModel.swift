//
//  OwnerModeViewModel.swift
//  Gym Flex Italia
//
//  DEBUG-only ViewModel for Owner Mode QR validation.
//

#if DEBUG
import Foundation
import SwiftUI
import Combine
import UIKit

/// ViewModel for Owner Mode QR validation
@MainActor
final class OwnerModeViewModel: ObservableObject {
    
    // MARK: - Published State
    
    /// Selected gym ID for validation context
    @Published var selectedGymId: String
    
    /// Raw QR input string (JSON payload)
    @Published var qrInput: String = ""
    
    /// Loading state during validation
    @Published var isLoading = false
    
    /// Validation result from service
    @Published var validationResult: QRValidationResult?
    
    /// Decoded payload (for display)
    @Published var decodedPayload: QRPayload?
    
    /// Generated usage report preview
    @Published var reportPreview: SessionUsageReport?
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Success message (e.g., "Copied to clipboard")
    @Published var successMessage: String?
    
    // MARK: - Dependencies
    
    private let validationService = MockQRValidationService.shared
    
    // MARK: - Computed Properties
    
    /// All gyms for picker
    var allGyms: [Gym] {
        MockDataStore.shared.gyms
    }
    
    /// Selected gym name
    var selectedGymName: String {
        allGyms.first { $0.id == selectedGymId }?.name ?? "Unknown Gym"
    }
    
    /// Whether we have a valid result to display
    var hasValidationResult: Bool {
        validationResult != nil
    }
    
    /// Whether we can generate a report (valid booking)
    var canGenerateReport: Bool {
        guard let result = validationResult else { return false }
        return result.bookingId != nil
    }
    
    /// Status color for the validation result
    var statusColor: Color {
        guard let result = validationResult else { return .secondary }
        switch result.status {
        case .valid:
            return .green
        case .alreadyCheckedIn:
            return .blue
        case .expired, .notStarted:
            return .orange
        case .invalid, .wrongGym, .cancelled:
            return .red
        }
    }
    
    /// Status icon for the validation result
    var statusIcon: String {
        guard let result = validationResult else { return "questionmark.circle" }
        switch result.status {
        case .valid:
            return "checkmark.circle.fill"
        case .alreadyCheckedIn:
            return "person.fill.checkmark"
        case .expired:
            return "clock.badge.exclamationmark"
        case .notStarted:
            return "clock"
        case .invalid:
            return "xmark.circle.fill"
        case .wrongGym:
            return "building.2.crop.circle.badge.exclamationmark"
        case .cancelled:
            return "xmark.octagon.fill"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Default to first gym
        self.selectedGymId = MockDataStore.shared.gyms.first?.id ?? "gym_1"
    }
    
    // MARK: - Actions
    
    /// Paste QR content from clipboard
    func pasteFromClipboard() {
        if let content = UIPasteboard.general.string {
            qrInput = content
            clearResults()
            SafeLog.log("OwnerMode: Pasted content from clipboard")
        } else {
            errorMessage = "Clipboard is empty"
        }
    }
    
    /// Clear QR input and results
    func clearInput() {
        qrInput = ""
        clearResults()
    }
    
    /// Clear validation results
    private func clearResults() {
        validationResult = nil
        decodedPayload = nil
        reportPreview = nil
        errorMessage = nil
        successMessage = nil
    }
    
    /// Load a sample valid QR payload from current active booking
    func loadSamplePayload() {
        // Try to find an active booking
        if let activeBooking = MockBookingStore.shared.currentUserSession() {
            let payload = QRPayload.generate(from: activeBooking)
            qrInput = payload.toQRString() ?? ""
            clearResults()
            successMessage = "Loaded QR from active session"
            SafeLog.log("OwnerMode: Loaded sample from active booking")
        } else {
            // Create a test payload
            let payload = validationService.createTestValidPayload(gymId: selectedGymId)
            qrInput = payload.toQRString() ?? ""
            clearResults()
            successMessage = "Loaded test QR payload"
            SafeLog.log("OwnerMode: Loaded test payload")
        }
    }
    
    /// Validate the QR payload
    func validate() async {
        guard !qrInput.isEmpty else {
            errorMessage = "Please enter or paste a QR payload"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        validationResult = nil
        decodedPayload = nil
        reportPreview = nil
        
        // Try to decode payload first for display
        decodedPayload = QRPayload.from(qrString: qrInput)
        
        // Validate through service
        let result = await validationService.validate(
            qrString: qrInput,
            validatorGymId: selectedGymId
        )
        
        validationResult = result
        isLoading = false
        
        SafeLog.log("OwnerMode: Validation complete, status=\(result.status.rawValue)")
    }
    
    /// Generate usage report preview
    func generateReportPreview() {
        guard let payload = decodedPayload,
              let bookingId = validationResult?.bookingId else {
            errorMessage = "No valid booking to generate report"
            return
        }
        
        // Look up booking
        guard let booking = MockBookingStore.shared.bookingById(bookingId) else {
            errorMessage = "Booking not found in store"
            return
        }
        
        // Create report
        let report = SessionUsageReport.create(
            booking: booking,
            checkInTime: booking.checkinTime ?? Date(),
            checkOutTime: nil, // Preview - no checkout yet
            extensionMinutes: 0,
            status: booking.status == .checkedIn ? .active : .completed,
            endReason: nil
        )
        
        reportPreview = report
        successMessage = "Report preview generated"
        SafeLog.log("OwnerMode: Generated report preview for booking \(bookingId)")
    }
    
    /// Copy report JSON to clipboard
    func copyReportJSON() {
        guard let report = reportPreview else {
            errorMessage = "No report to copy"
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(report)
            if let json = String(data: data, encoding: .utf8) {
                UIPasteboard.general.string = json
                successMessage = "Report JSON copied to clipboard"
                SafeLog.log("OwnerMode: Copied report JSON to clipboard")
            }
        } catch {
            errorMessage = "Failed to encode report: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Formatters
    
    /// Format date for display
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
#endif
