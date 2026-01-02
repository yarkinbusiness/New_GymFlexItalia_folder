//
//  MockDataStore.swift
//  Gym Flex Italia
//
//  ╔════════════════════════════════════════════════════════════════════════════╗
//  ║  SINGLE SOURCE OF TRUTH FOR ALL GYM DATA                                   ║
//  ║                                                                            ║
//  ║  This is the ONLY place where gym data should be created.                  ║
//  ║  Do NOT duplicate gym models in other files.                               ║
//  ║  All services MUST use MockDataStore.shared.gyms or gymById(_:)            ║
//  ╚════════════════════════════════════════════════════════════════════════════╝
//

import Foundation

/// Singleton providing canonical mock data for consistent cross-feature behavior.
///
/// **IMPORTANT**: This is the single source of truth for all gym data.
/// All booking, wallet, check-in, and profile features must resolve gym info
/// via `gymById(_:)` using the gym's ID.
///
/// **DO NOT**:
/// - Create `[Gym]` arrays in other files
/// - Duplicate gym names or prices in bookings/transactions
/// - Use hardcoded gym data outside of this file
///
/// **DO**:
/// - Store only `gymId` in bookings and transactions
/// - Resolve gym details via `MockDataStore.shared.gymById(id)`
final class MockDataStore {
    
    // MARK: - Singleton
    
    static let shared = MockDataStore()
    
    private init() {}
    
    // MARK: - Canonical Gyms
    
    /// The canonical list of gyms used throughout the app.
    /// All mock services reference these gyms by ID.
    lazy var gyms: [Gym] = generateCanonicalGyms()
    
    /// Look up a gym by its ID
    /// - Parameter id: The gym ID (e.g., "gym_1")
    /// - Returns: The gym if found, nil otherwise
    ///
    /// **DEBUG**: Will assert if gym is not found, helping catch bad IDs early.
    func gymById(_ id: String) -> Gym? {
        let gym = gyms.first { $0.id == id }
        
        #if DEBUG
        if gym == nil && !id.isEmpty {
            print("⚠️ MockDataStore.gymById: No gym found for id='\(id)'. Valid IDs: \(gyms.map { $0.id })")
            // Uncomment to fail fast during development:
            // assertionFailure("Gym not found for id: \(id)")
        }
        #endif
        
        return gym
    }
    
    /// Get a random gym from the canonical list
    func randomGym() -> Gym {
        gyms.randomElement() ?? gyms[0]
    }
    
    // MARK: - Reference Code Generators
    
    /// Generates a booking reference code in format "GF-XXXXXX"
    static func makeBookingRef() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let suffix = String((0..<6).map { _ in chars.randomElement()! })
        return "GF-\(suffix)"
    }
    
    /// Generates a wallet transaction reference code in format "WL-XXXXXX"
    static func makeWalletRef() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let suffix = String((0..<6).map { _ in chars.randomElement()! })
        return "WL-\(suffix)"
    }
    
    /// Generates a check-in code in format "CHK-XXXXXX"
    static func makeCheckinCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let suffix = String((0..<6).map { _ in chars.randomElement()! })
        return "CHK-\(suffix)"
    }
    
    // MARK: - Mock User
    
    /// The mock user ID used across all services
    static let mockUserId = "user_demo_001"
    
    // MARK: - Private: Gym Data Generation
    
    /// Generates the canonical list of 12 gyms in Rome.
    /// Amenities and equipment are deterministic based on gym index.
    private func generateCanonicalGyms() -> [Gym] {
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
                amenities: deterministicAmenities(for: index),
                equipment: deterministicEquipment(for: index),
                workoutTypes: [.strength, .cardio],
                phoneNumber: "+39 06 \(1000000 + index * 111111)",
                email: "info@\(data.name.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "'", with: "")).it",
                website: "https://www.\(data.name.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "'", with: "")).it",
                openingHours: defaultOpeningHours(),
                rating: data.rating,
                reviewCount: 100 + index * 50,
                totalBookings: 500 + index * 150,
                isActive: true,
                isVerified: index < 6, // Top 6 gyms are verified
                createdAt: Date().addingTimeInterval(-Double(365 - index * 30) * 86400),
                updatedAt: Date()
            )
        }
    }
    
    /// Deterministic amenities based on gym index
    private func deterministicAmenities(for index: Int) -> [Amenity] {
        let allAmenities = Amenity.allCases
        // Each gym gets a consistent subset based on its index
        let start = index % allAmenities.count
        let count = 4 + (index % 5) // 4-8 amenities
        var result: [Amenity] = []
        for i in 0..<count {
            result.append(allAmenities[(start + i) % allAmenities.count])
        }
        return result
    }
    
    /// Deterministic equipment based on gym index
    private func deterministicEquipment(for index: Int) -> [Equipment] {
        let allEquipment = Equipment.allCases
        // Each gym gets a consistent subset based on its index
        let start = (index * 2) % allEquipment.count
        let count = 6 + (index % 7) // 6-12 equipment items
        var result: [Equipment] = []
        for i in 0..<count {
            result.append(allEquipment[(start + i) % allEquipment.count])
        }
        return result
    }
    
    /// Standard opening hours for all gyms
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

