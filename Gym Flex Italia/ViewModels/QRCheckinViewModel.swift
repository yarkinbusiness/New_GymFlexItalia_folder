//
//  QRCheckinViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import UIKit
import Combine

/// ViewModel for QR check-in functionality
@MainActor
final class QRCheckinViewModel: ObservableObject {
    
    @Published var booking: Booking?
    @Published var qrCodeImage: UIImage?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isExpired = false
    @Published var isCheckedIn = false
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLevelUp = false
    @Published var newLevel: Int?
    
    private var bookingHistoryService: BookingHistoryServiceProtocol?
    private var checkInService: CheckInServiceProtocol?
    private var profileService: ProfileServiceProtocol?
    private let qrService = QRService.shared
    private let realtimeService = RealtimeService.shared
    
    private var timer: Timer?
    
    /// Configures the services to use
    func configure(
        bookingHistoryService: BookingHistoryServiceProtocol,
        checkInService: CheckInServiceProtocol,
        profileService: ProfileServiceProtocol
    ) {
        self.bookingHistoryService = bookingHistoryService
        self.checkInService = checkInService
        self.profileService = profileService
    }
    
    // MARK: - Load Booking & Generate QR
    func loadBooking(bookingId: String) async {
        guard let service = bookingHistoryService else {
            errorMessage = "Services not configured"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            booking = try await service.fetchBooking(id: bookingId)
            
            if let booking = booking, booking.canCheckIn {
                await generateQRCode()
                startTimer()
                subscribeToBookingUpdates(bookingId: bookingId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Generate QR Code
    func generateQRCode() async {
        guard let booking = booking else { return }
        
        // Use existing QR code data from booking
        if let qrData = booking.qrCodeData,
           let image = qrService.generateQRCode(from: qrData) {
            qrCodeImage = image
        }
    }
    
    // MARK: - Check In
    func checkIn() async {
        guard let booking = booking,
              let qrCode = booking.checkinCode,
              let service = checkInService else {
            errorMessage = "Invalid booking or QR code"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await service.checkIn(
                code: qrCode,
                bookingId: booking.id
            )
            
            self.booking = result.booking
            isCheckedIn = true
            
            // Record workout for avatar progression
            await recordWorkout()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Check Out
    func checkOut() async {
        guard let booking = booking,
              let service = checkInService else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedBooking = try await service.checkOut(bookingId: booking.id)
            self.booking = updatedBooking
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Record Workout (Avatar Progression)
    private func recordWorkout() async {
        guard let booking = booking,
              let service = profileService else { return }
        
        do {
            let oldLevel = AuthService.shared.currentUser?.avatarLevel ?? 1
            let updatedProfile = try await service.recordWorkout(bookingId: booking.id)
            let newLevelValue = updatedProfile.avatarLevel
            
            // Check for level up
            if newLevelValue > oldLevel {
                newLevel = newLevelValue
                showLevelUp = true
            }
        } catch {
            #if DEBUG
            print("Failed to record workout: \(error)")
            #endif
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        guard let booking = booking,
              let expiresAt = booking.qrCodeExpiresAt else { return }
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateTimeRemaining(expiresAt: expiresAt)
            }
        }
    }
    
    private func updateTimeRemaining(expiresAt: Date) {
        let remaining = expiresAt.timeIntervalSinceNow
        
        if remaining > 0 {
            timeRemaining = remaining
            isExpired = false
        } else {
            timeRemaining = 0
            isExpired = true
            timer?.invalidate()
        }
    }
    
    func formattedTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Realtime Updates
    private func subscribeToBookingUpdates(bookingId: String) {
        realtimeService.subscribeToBookingUpdates(bookingId: bookingId) { [weak self] updatedBooking in
            Task { @MainActor in
                self?.booking = updatedBooking
                if updatedBooking.status == .checkedIn {
                    self?.isCheckedIn = true
                }
            }
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
    
    deinit {
        timer?.invalidate()
    }
}

