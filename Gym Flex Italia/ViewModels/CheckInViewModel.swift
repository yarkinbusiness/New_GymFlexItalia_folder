//
//  CheckInViewModel.swift
//  Gym Flex Italia
//
//  ViewModel for the manual check-in flow
//

import Foundation
import Combine

/// ViewModel for the check-in view with manual code entry
@MainActor
final class CheckInViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The check-in code entered by the user
    @Published var checkInCode: String = ""
    
    /// Whether a check-in operation is in progress
    @Published var isLoading = false
    
    /// Error message to display (nil if no error)
    @Published var errorMessage: String?
    
    /// Success result after successful check-in
    @Published var successResult: CheckInResult?
    
    // MARK: - Computed Properties
    
    /// Whether the current code format is valid
    var isCodeValid: Bool {
        let pattern = "^CHK-[A-Z0-9]{6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(checkInCode.startIndex..., in: checkInCode)
        return regex?.firstMatch(in: checkInCode, options: [], range: range) != nil
    }
    
    /// Whether the submit button should be enabled
    var canSubmit: Bool {
        isCodeValid && !isLoading
    }
    
    /// Whether check-in was successful
    var isSuccess: Bool {
        successResult != nil
    }
    
    // MARK: - Methods
    
    /// Submits the check-in code for validation
    /// - Parameters:
    ///   - code: The check-in code to validate
    ///   - bookingId: The booking ID to check in
    ///   - service: The check-in service to use
    func submit(code: String, bookingId: String, using service: CheckInServiceProtocol) async {
        isLoading = true
        errorMessage = nil
        successResult = nil
        
        do {
            let result = try await service.checkIn(code: code, bookingId: bookingId)
            successResult = result
        } catch let error as CheckInServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Resets the view model to initial state
    func reset() {
        checkInCode = ""
        isLoading = false
        errorMessage = nil
        successResult = nil
    }
}
