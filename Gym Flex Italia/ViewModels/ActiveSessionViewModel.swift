//
//  ActiveSessionViewModel.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/21/25.
//

import Foundation
import Combine
import MapKit

/// ViewModel for Active Session view
@MainActor
class ActiveSessionViewModel: ObservableObject {
    @Published var booking: Booking?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isExpired: Bool = false
    @Published var showInsufficientFunds: Bool = false
    @Published var isExtending: Bool = false
    @Published var errorMessage: String?
    @Published var walletBalance: Double = 0
    
    private var checkInService: CheckInServiceProtocol?
    private var timer: Timer?
    
    init(booking: Booking? = nil) {
        self.booking = booking
        if booking != nil {
            calculateTimeRemaining()
            startTimer()
        }
        Task {
            await loadWalletBalance()
        }
    }
    
    /// Configures the service to use for check-in operations
    func configure(checkInService: CheckInServiceProtocol) {
        self.checkInService = checkInService
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        stopTimer() // Ensure no existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.calculateTimeRemaining()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func calculateTimeRemaining() {
        guard let booking = booking else {
            timeRemaining = 0
            isExpired = true
            return
        }
        timeRemaining = booking.endTime.timeIntervalSinceNow
        isExpired = timeRemaining <= 0
    }
    
    // MARK: - Wallet Balance
    func loadWalletBalance() async {
        // Use WalletStore (single source of truth) instead of legacy WalletService
        walletBalance = WalletStore.shared.balance
    }
    
    // MARK: - Extension Pricing
    func extensionPrice(minutes: Int) -> Double {
        guard let booking = booking else { return 0 }
        return (booking.pricePerHour * Double(minutes)) / 60.0
    }
    
    // MARK: - Session Extension
    func extendSession(additionalMinutes: Int) async {
        guard let booking = booking, !isExtending, !isExpired else { return }
        guard let service = checkInService else {
            errorMessage = "Check-in service not configured"
            return
        }
        
        let cost = extensionPrice(minutes: additionalMinutes)
        
        // Check if user has sufficient balance
        if walletBalance < cost {
            showInsufficientFunds = true
            // Auto-dismiss after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    showInsufficientFunds = false
                }
            }
            return
        }
        
        isExtending = true
        
        do {
            let updatedBooking = try await service.extendSession(
                bookingId: booking.id,
                additionalMinutes: additionalMinutes
            )
            
            // Update local state
            self.booking = updatedBooking
            
            // Sync with BookingManager for app-wide state
            BookingManager.shared.setActiveBooking(updatedBooking)
            
            // Refresh timer and balance
            calculateTimeRemaining()
            await loadWalletBalance()
        } catch {
            if error.localizedDescription.contains("Insufficient") {
                showInsufficientFunds = true
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        showInsufficientFunds = false
                    }
                }
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isExtending = false
    }
    
    // MARK: - Update Booking
    func update(booking: Booking?) {
        self.booking = booking
        if let booking = booking {
            calculateTimeRemaining()
            // If the booking is no longer active, stop timer
            if booking.status == .completed || booking.status == .cancelled {
                stopTimer()
            } else if timer == nil {
                startTimer()
            }
        } else {
            stopTimer()
            timeRemaining = 0
        }
    }
    
    // MARK: - Check Out
    func checkOut() async {
        guard let booking = booking else { return }
        guard let service = checkInService else {
            errorMessage = "Check-in service not configured"
            return
        }
        do {
            let updatedBooking = try await service.checkOut(bookingId: booking.id)
            update(booking: updatedBooking)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Maps Integration
    func openMapsDirections() {
        guard let booking = booking,
              let gymName = booking.gymName,
              let gymAddress = booking.gymAddress else { return }
        
        Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = gymAddress
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                if let mapItem = response.mapItems.first {
                    mapItem.name = gymName
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                }
            } catch {
                print("Failed to find location: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Formatted Time
    var formattedTimeRemaining: String {
        if isExpired {
            return "Session Ended"
        }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
