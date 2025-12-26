//
//  MockGymDataProvider.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import Foundation
import CoreLocation

/// Mock data provider for Rome-based gyms
/// This can be replaced with real API calls later
final class MockGymDataProvider {
    
    static let shared = MockGymDataProvider()
    
    // Rome city center coordinates
    private let romeCenter = CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)
    
    private init() {}
    
    /// Generate fake Rome gyms with realistic names and locations
    func generateRomeGyms() -> [Gym] {
        let gymData: [(name: String, address: String, lat: Double, lon: Double, price: Double, rating: Double)] = [
            ("FitRoma Center", "Via del Corso 123, 00186 Roma", 41.9028, 12.4964, 3.0, 4.8),
            ("Colosseo Fitness Lab", "Via dei Fori Imperiali 45, 00184 Roma", 41.8902, 12.4922, 3.5, 4.6),
            ("Trastevere Active Hub", "Via di Trastevere 78, 00153 Roma", 41.8897, 12.4694, 2.5, 4.7),
            ("Pantheon Power Gym", "Piazza della Rotonda 12, 00186 Roma", 41.8986, 12.4769, 4.0, 4.9),
            ("Vatican City Fitness", "Via della Conciliazione 88, 00193 Roma", 41.9029, 12.4534, 3.0, 4.5),
            ("Spanish Steps Strength", "Via dei Condotti 56, 00187 Roma", 41.9060, 12.4823, 3.5, 4.8),
            ("Trevi Fountain Flex", "Via del Tritone 34, 00187 Roma", 41.9009, 12.4833, 2.0, 4.4),
            ("Campo de' Fiori Fit", "Piazza Campo de' Fiori 22, 00186 Roma", 41.8956, 12.4723, 2.5, 4.6),
            ("Testaccio Muscle House", "Via di Testaccio 67, 00153 Roma", 41.8806, 12.4778, 2.0, 4.3),
            ("Prati Elite Training", "Via Cola di Rienzo 89, 00193 Roma", 41.9075, 12.4708, 3.5, 4.7),
            ("Monti Athletic Club", "Via dei Serpenti 45, 00184 Roma", 41.8950, 12.4900, 2.5, 4.5),
            ("Pigneto Power Center", "Via del Pigneto 123, 00176 Roma", 41.8861, 12.5281, 2.0, 4.2),
            ("EUR Sports Complex", "Viale Europa 200, 00144 Roma", 41.8333, 12.4667, 3.0, 4.6),
            ("San Lorenzo Fitness", "Via dei Sabelli 34, 00185 Roma", 41.8994, 12.5156, 2.5, 4.4),
            ("Ostiense Training Hub", "Via Ostiense 156, 00154 Roma", 41.8750, 12.4800, 2.0, 4.3)
        ]
        
        return gymData.enumerated().map { index, data in
            Gym(
                id: "gym_\(index + 1)",
                name: data.name,
                description: "Modern fitness center in the heart of Rome with state-of-the-art equipment and professional trainers.",
                address: data.address,
                city: "Roma",
                region: "Lazio",
                postalCode: "00100",
                country: "Italy",
                latitude: data.lat,
                longitude: data.lon,
                pricePerHour: data.price,
                currency: "EUR",
                coverImageURL: nil,
                imageURLs: [],
                amenities: generateRandomAmenities(),
                equipment: generateRandomEquipment(),
                workoutTypes: [.strength, .cardio],
                phoneNumber: "+39 06 \(Int.random(in: 1000000...9999999))",
                email: "info@\(data.name.lowercased().replacingOccurrences(of: " ", with: "")).it",
                website: "https://www.\(data.name.lowercased().replacingOccurrences(of: " ", with: "")).it",
                openingHours: generateOpeningHours(),
                rating: data.rating,
                reviewCount: Int.random(in: 50...500),
                totalBookings: Int.random(in: 100...2000),
                isActive: true,
                isVerified: true,
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...31536000)), // Random date in last year
                updatedAt: Date()
            )
        }
    }
    
    private func generateRandomAmenities() -> [Amenity] {
        let allAmenities = Amenity.allCases
        let count = Int.random(in: 4...8)
        return Array(allAmenities.shuffled().prefix(count))
    }
    
    private func generateRandomEquipment() -> [Equipment] {
        let allEquipment = Equipment.allCases
        let count = Int.random(in: 6...12)
        return Array(allEquipment.shuffled().prefix(count))
    }
    
    private func generateOpeningHours() -> OpeningHours {
        let dayHours = OpeningHours.DayHours(
            open: "06:00",
            close: "23:00",
            isClosed: false
        )
        
        return OpeningHours(
            monday: dayHours,
            tuesday: dayHours,
            wednesday: dayHours,
            thursday: dayHours,
            friday: dayHours,
            saturday: dayHours,
            sunday: OpeningHours.DayHours(open: "08:00", close: "20:00", isClosed: false)
        )
    }
}

