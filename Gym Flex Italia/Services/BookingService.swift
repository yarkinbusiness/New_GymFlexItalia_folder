//
//  BookingService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation

/// Booking management service
final class BookingService {
    
    static let shared = BookingService()
    
    private let baseURL = AppConfig.API.baseURL
    private let authService = AuthService.shared
    
    private init() {}
    
    // MARK: - Create Booking
    func createBooking(gymId: String, startTime: Date, duration: Int) async throws -> Booking {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            
            // Create a new mock booking
            let gym = MockData.sampleGyms.first(where: { $0.id == gymId }) ?? MockData.sampleGyms[0]
            
            return Booking(
                id: "booking_mock_\(Int.random(in: 1000...9999))",
                userId: "user_123",
                gymId: gymId,
                gymName: gym.name,
                gymAddress: gym.address,
                gymCoverImageURL: gym.coverImageURL,
                startTime: startTime,
                endTime: startTime.addingTimeInterval(TimeInterval(duration * 60)),
                duration: duration,
                pricePerHour: gym.pricePerHour,
                totalPrice: (gym.pricePerHour * Double(duration)) / 60.0,
                currency: gym.currency,
                status: .confirmed,
                checkinCode: nil,
                checkinTime: nil,
                checkoutTime: nil,
                qrCodeData: generateUniqueQRCode(bookingId: "booking_mock_\(Int.random(in: 1000...9999))", userId: "user_123"),
                qrCodeExpiresAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                cancelledAt: nil,
                cancellationReason: nil
            )
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = ISO8601DateFormatter()
        let body: [String: Any] = [
            "gym_id": gymId,
            "start_time": dateFormatter.string(from: startTime),
            "duration": duration
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.createFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Booking.self, from: data)
    }
    
    // MARK: - Fetch Bookings
    func fetchBookings(status: BookingStatus? = nil) async throws -> [Booking] {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s delay
            if let status = status {
                return MockData.sampleBookings.filter { $0.status == status }
            }
            return MockData.sampleBookings
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        var components = URLComponents(string: "\(baseURL)/bookings")!
        if let status = status {
            components.queryItems = [
                URLQueryItem(name: "status", value: status.rawValue)
            ]
        }
        
        guard let url = components.url else {
            throw BookingError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Booking].self, from: data)
    }
    
    // MARK: - Fetch Single Booking
    func fetchBooking(id: String) async throws -> Booking {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            return MockData.sampleBookings.first(where: { $0.id == id }) ?? MockData.sampleBookings[0]
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.fetchFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Booking.self, from: data)
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(id: String, reason: String? = nil) async throws -> Booking {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            // Return a cancelled version of the booking
            if let booking = MockData.sampleBookings.first(where: { $0.id == id }) {
                return Booking(
                    id: booking.id,
                    userId: booking.userId,
                    gymId: booking.gymId,
                    gymName: booking.gymName,
                    gymAddress: booking.gymAddress,
                    gymCoverImageURL: booking.gymCoverImageURL,
                    startTime: booking.startTime,
                    endTime: booking.endTime,
                    duration: booking.duration,
                    pricePerHour: booking.pricePerHour,
                    totalPrice: booking.totalPrice,
                    currency: booking.currency,
                    status: .cancelled,
                    checkinCode: booking.checkinCode,
                    checkinTime: booking.checkinTime,
                    checkoutTime: booking.checkoutTime,
                    qrCodeData: nil,
                    qrCodeExpiresAt: nil,
                    createdAt: booking.createdAt,
                    updatedAt: Date(),
                    cancelledAt: Date(),
                    cancellationReason: reason
                )
            }
            throw BookingError.cancelFailed
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings/\(id)/cancel")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let reason = reason {
            let body: [String: Any] = ["reason": reason]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.cancelFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Booking.self, from: data)
    }
    
    // MARK: - Check In
    func checkIn(bookingId: String, qrCode: String) async throws -> Booking {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            if let booking = MockData.sampleBookings.first(where: { $0.id == bookingId }) {
                return Booking(
                    id: booking.id,
                    userId: booking.userId,
                    gymId: booking.gymId,
                    gymName: booking.gymName,
                    gymAddress: booking.gymAddress,
                    gymCoverImageURL: booking.gymCoverImageURL,
                    startTime: booking.startTime,
                    endTime: booking.endTime,
                    duration: booking.duration,
                    pricePerHour: booking.pricePerHour,
                    totalPrice: booking.totalPrice,
                    currency: booking.currency,
                    status: .checkedIn,
                    checkinCode: booking.checkinCode,
                    checkinTime: Date(),
                    checkoutTime: nil,
                    qrCodeData: booking.qrCodeData,
                    qrCodeExpiresAt: booking.qrCodeExpiresAt,
                    createdAt: booking.createdAt,
                    updatedAt: Date(),
                    cancelledAt: nil,
                    cancellationReason: nil
                )
            }
            throw BookingError.checkinFailed
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/checkin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["qr_code": qrCode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.checkinFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Booking.self, from: data)
    }
    
    // MARK: - Check Out
    func checkOut(bookingId: String) async throws -> Booking {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
             if let booking = MockData.sampleBookings.first(where: { $0.id == bookingId }) {
                return booking // Already completed in mock
            }
            throw BookingError.checkoutFailed
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/checkout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.checkoutFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Booking.self, from: data)
    }
    
    // MARK: - Generate QR Code
    func generateQRCode(bookingId: String) async throws -> String {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            return "mock_qr_generated_\(bookingId)"
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/qr-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.qrGenerationFailed
        }
        
        let qrResponse = try JSONDecoder().decode(QRCodeResponse.self, from: data)
        return qrResponse.qrCode
    }
    
    // MARK: - Session Extension
    func extendSession(bookingId: String, additionalMinutes: Int) async throws -> Booking {
        if AppConfig.API.useMocks {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
            
            // Find the booking and extend it
            let mockBookings = await MainActor.run { MockData.sampleBookings }
            let mockGyms = await MainActor.run { MockData.sampleGyms }
            
            if let index = mockBookings.firstIndex(where: { $0.id == bookingId }) {
                let booking = mockBookings[index]
                let gym = mockGyms.first(where: { $0.id == booking.gymId }) ?? mockGyms[0]
                let additionalCost = (gym.pricePerHour * Double(additionalMinutes)) / 60.0
                
                // Check wallet balance
                let walletBalance = try? await WalletService.shared.fetchBalance()
                if let balance = walletBalance, balance < additionalCost {
                    throw BookingError.insufficientFunds
                }
                
                let updatedBooking = Booking(
                    id: booking.id,
                    userId: booking.userId,
                    gymId: booking.gymId,
                    gymName: booking.gymName,
                    gymAddress: booking.gymAddress,
                    gymCoverImageURL: booking.gymCoverImageURL,
                    startTime: booking.startTime,
                    endTime: booking.endTime.addingTimeInterval(TimeInterval(additionalMinutes * 60)),
                    duration: booking.duration + additionalMinutes,
                    pricePerHour: booking.pricePerHour,
                    totalPrice: booking.totalPrice + additionalCost,
                    currency: booking.currency,
                    status: booking.status,
                    checkinCode: booking.checkinCode,
                    checkinTime: booking.checkinTime,
                    checkoutTime: nil,
                    qrCodeData: booking.qrCodeData,
                    qrCodeExpiresAt: booking.qrCodeExpiresAt,
                    createdAt: booking.createdAt,
                    updatedAt: Date(),
                    cancelledAt: nil,
                    cancellationReason: nil
                )
                
                // UPDATE SOURCE OF TRUTH
                await MainActor.run {
                    MockData.sampleBookings[index] = updatedBooking
                }
                
                return updatedBooking
            }
            throw BookingError.fetchFailed
        }
        
        guard let token = authService.getStoredToken() else {
            throw BookingError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/bookings/\(bookingId)/extend")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["additional_minutes": additionalMinutes]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BookingError.extensionFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Booking.self, from: data)
    }
    
    // MARK: - Helper Methods
    private func generateUniqueQRCode(bookingId: String, userId: String) -> String {
        let timestamp = Date().timeIntervalSince1970
        let uniqueString = "\(userId)-\(bookingId)-\(timestamp)"
        return uniqueString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
}

// MARK: - QR Code Response
struct QRCodeResponse: Codable {
    let qrCode: String
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case qrCode = "qr_code"
        case expiresAt = "expires_at"
    }
}

// MARK: - Booking Errors
enum BookingError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case createFailed
    case fetchFailed
    case cancelFailed
    case checkinFailed
    case checkoutFailed
    case qrGenerationFailed
    case extensionFailed
    case insufficientFunds
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .createFailed:
            return "Failed to create booking"
        case .fetchFailed:
            return "Failed to fetch bookings"
        case .cancelFailed:
            return "Failed to cancel booking"
        case .checkinFailed:
            return "Check-in failed"
        case .checkoutFailed:
            return "Check-out failed"
        case .qrGenerationFailed:
            return "Failed to generate QR code"
        case .extensionFailed:
            return "Failed to extend session"
        case .insufficientFunds:
            return "Insufficient funds in wallet"
        }
    }
}
