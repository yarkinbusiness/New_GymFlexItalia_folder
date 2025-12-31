//
//  MockGymService.swift
//  Gym Flex Italia
//
//  Mock implementation for testing and demo mode
//

import Foundation

/// Mock implementation of GymServiceProtocol
/// Returns realistic fake gym data for Rome area
final class MockGymService: GymServiceProtocol {
    
    // Cached gyms for consistent data across calls
    private lazy var mockGyms: [Gym] = generateMockGyms()
    
    // MARK: - GymServiceProtocol
    
    func fetchGyms() async throws -> [Gym] {
        // Simulate network delay (300-500ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 300_000_000...500_000_000))
        return mockGyms
    }
    
    func fetchGymDetail(id: String) async throws -> Gym {
        // Simulate network delay (200-400ms)
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...400_000_000))
        
        // Check for "fail" in gymId to trigger error (for testing error UI)
        if id.lowercased().contains("fail") {
            throw GymServiceError.fetchFailed
        }
        
        // Find gym by ID
        guard let gym = mockGyms.first(where: { $0.id == id }) else {
            throw GymServiceError.gymNotFound
        }
        
        return gym
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockGyms() -> [Gym] {
        let gymData: [(name: String, address: String, lat: Double, lon: Double, price: Double, rating: Double, desc: String)] = [
            (
                "FitRoma Center",
                "Via del Corso 123, 00186 Roma",
                41.9028, 12.4964, 3.0, 4.8,
                "Premium fitness center in the heart of Rome featuring cutting-edge cardio equipment, a spacious strength training area, and dedicated yoga studios. Our certified trainers provide personalized workout plans."
            ),
            (
                "Colosseo Fitness Lab",
                "Via dei Fori Imperiali 45, 00184 Roma",
                41.8902, 12.4922, 3.5, 4.6,
                "Train like a gladiator near the iconic Colosseum. This historic-meets-modern gym offers CrossFit classes, Olympic lifting platforms, and stunning views of ancient Rome."
            ),
            (
                "Trastevere Active Hub",
                "Via di Trastevere 78, 00153 Roma",
                41.8897, 12.4694, 2.5, 4.7,
                "Bohemian charm meets fitness excellence. Located in trendy Trastevere, we offer functional training, spinning classes, and a rooftop stretching area."
            ),
            (
                "Pantheon Power Gym",
                "Piazza della Rotonda 12, 00186 Roma",
                41.8986, 12.4769, 4.0, 4.9,
                "Elite training facility steps from the Pantheon. Features private training suites, recovery spa, and nutrition consulting. Our flagship location for serious athletes."
            ),
            (
                "Vatican City Fitness",
                "Via della Conciliazione 88, 00193 Roma",
                41.9029, 12.4534, 3.0, 4.5,
                "Peaceful, well-equipped gym near Vatican City. Ideal for travelers and locals seeking a calm workout environment with full amenities."
            ),
            (
                "Spanish Steps Strength",
                "Via dei Condotti 56, 00187 Roma",
                41.9060, 12.4823, 3.5, 4.8,
                "Luxury boutique gym in Rome's most fashionable district. Personal training, Pilates reformer, and post-workout smoothie bar included."
            ),
            (
                "Trevi Fountain Flex",
                "Via del Tritone 34, 00187 Roma",
                41.9009, 12.4833, 2.0, 4.4,
                "Budget-friendly option near Trevi Fountain. Great for quick workouts with essential equipment and friendly staff."
            ),
            (
                "Campo de' Fiori Fit",
                "Piazza Campo de' Fiori 22, 00186 Roma",
                41.8956, 12.4723, 2.5, 4.6,
                "Morning workouts with market vendors nearby! This energetic gym offers group fitness classes and a community atmosphere."
            ),
            (
                "Testaccio Muscle House",
                "Via di Testaccio 67, 00153 Roma",
                41.8806, 12.4778, 2.0, 4.3,
                "Old-school bodybuilding gym in authentic Testaccio. Heavy iron, chalk buckets, and no-frills training for dedicated lifters."
            ),
            (
                "Prati Elite Training",
                "Via Cola di Rienzo 89, 00193 Roma",
                41.9075, 12.4708, 3.5, 4.7,
                "Modern fitness concept in the Prati district. Virtual reality cycling, smart equipment tracking, and AI-powered workout suggestions."
            ),
            (
                "Monti Athletic Club",
                "Via dei Serpenti 45, 00184 Roma",
                41.8950, 12.4900, 2.5, 4.5,
                "Neighborhood favorite in the historic Monti quarter. Boxing ring, climbing wall, and a welcoming community of fitness enthusiasts."
            ),
            (
                "EUR Sports Complex",
                "Viale Europa 200, 00144 Roma",
                41.8333, 12.4667, 3.0, 4.6,
                "Massive sports complex in the EUR district. Indoor pool, basketball courts, running track, and a 3-floor gym with every equipment imaginable."
            )
        ]
        
        return gymData.enumerated().map { index, data in
            Gym(
                id: "gym_\(index + 1)",
                name: data.name,
                description: data.desc,
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
                amenities: randomAmenities(),
                equipment: randomEquipment(),
                workoutTypes: [.strength, .cardio],
                phoneNumber: "+39 06 \(Int.random(in: 1000000...9999999))",
                email: "info@\(data.name.lowercased().replacingOccurrences(of: " ", with: "")).it",
                website: "https://www.\(data.name.lowercased().replacingOccurrences(of: " ", with: "")).it",
                openingHours: defaultOpeningHours(),
                rating: data.rating,
                reviewCount: Int.random(in: 50...500),
                totalBookings: Int.random(in: 100...2000),
                isActive: true,
                isVerified: Bool.random() || index < 4, // Ensure top gyms are verified
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...31536000)),
                updatedAt: Date()
            )
        }
    }
    
    private func randomAmenities() -> [Amenity] {
        let allAmenities = Amenity.allCases
        let count = Int.random(in: 4...8)
        return Array(allAmenities.shuffled().prefix(count))
    }
    
    private func randomEquipment() -> [Equipment] {
        let allEquipment = Equipment.allCases
        let count = Int.random(in: 6...12)
        return Array(allEquipment.shuffled().prefix(count))
    }
    
    private func defaultOpeningHours() -> OpeningHours {
        let weekdayHours = OpeningHours.DayHours(open: "06:00", close: "23:00", isClosed: false)
        let sundayHours = OpeningHours.DayHours(open: "08:00", close: "20:00", isClosed: false)
        
        return OpeningHours(
            monday: weekdayHours,
            tuesday: weekdayHours,
            wednesday: weekdayHours,
            thursday: weekdayHours,
            friday: weekdayHours,
            saturday: weekdayHours,
            sunday: sundayHours
        )
    }
}
