//
//  Gym.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import CoreLocation

/// Gym/Fitness Center model
struct Gym: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var address: String
    var city: String
    var region: String
    var postalCode: String
    var country: String
    
    // Coordinates
    var latitude: Double
    var longitude: Double
    
    // Pricing
    var pricePerHour: Double
    var currency: String
    
    // Media
    var coverImageURL: String?
    var imageURLs: [String]
    
    // Amenities & Features
    var amenities: [Amenity]
    var equipment: [Equipment]
    var workoutTypes: [WorkoutType]
    
    // Contact & Hours
    var phoneNumber: String?
    var email: String?
    var website: String?
    var openingHours: OpeningHours?
    
    // Ratings & Stats
    var rating: Double?
    var reviewCount: Int
    var totalBookings: Int
    
    // Status
    var isActive: Bool
    var isVerified: Bool
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case address
        case city
        case region
        case postalCode = "postal_code"
        case country
        case latitude
        case longitude
        case pricePerHour = "price_per_hour"
        case currency
        case coverImageURL = "cover_image_url"
        case imageURLs = "image_urls"
        case amenities
        case equipment
        case workoutTypes = "workout_types"
        case phoneNumber = "phone_number"
        case email
        case website
        case openingHours = "opening_hours"
        case rating
        case reviewCount = "review_count"
        case totalBookings = "total_bookings"
        case isActive = "is_active"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed property for CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Distance calculation helper
    func distance(from location: CLLocation) -> CLLocationDistance {
        let gymLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: gymLocation)
    }
}

// MARK: - Supporting Types
enum Amenity: String, Codable, CaseIterable {
    case showers
    case lockers
    case parking
    case wifi
    case airConditioning = "air_conditioning"
    case sauna
    case pool
    case cafe
    case personalTrainer = "personal_trainer"
    case groupClasses = "group_classes"
    case towelService = "towel_service"
    case waterStation = "water_station"
    
    var displayName: String {
        switch self {
        case .showers: return "Showers"
        case .lockers: return "Lockers"
        case .parking: return "Parking"
        case .wifi: return "WiFi"
        case .airConditioning: return "Air Conditioning"
        case .sauna: return "Sauna"
        case .pool: return "Pool"
        case .cafe: return "Café"
        case .personalTrainer: return "Personal Trainer"
        case .groupClasses: return "Group Classes"
        case .towelService: return "Towel Service"
        case .waterStation: return "Water Station"
        }
    }
    
    var icon: String {
        switch self {
        case .showers: return "shower.fill"
        case .lockers: return "lock.fill"
        case .parking: return "parkingsign.circle.fill"
        case .wifi: return "wifi"
        case .airConditioning: return "air.conditioner.horizontal"
        case .sauna: return "flame.fill"
        case .pool: return "figure.pool.swim"
        case .cafe: return "cup.and.saucer.fill"
        case .personalTrainer: return "person.fill"
        case .groupClasses: return "person.3.fill"
        case .towelService: return "t.square.fill"
        case .waterStation: return "drop.fill"
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case treadmills
    case dumbbells
    case barbells
    case benchPress = "bench_press"
    case squatRack = "squat_rack"
    case cableStation = "cable_station"
    case kettlebells
    case pullUpBar = "pull_up_bar"
    case rowingMachine = "rowing_machine"
    case spinBikes = "spin_bikes"
    case ellipticals
    case battlingRopes = "battling_ropes"
    case boxingBag = "boxing_bag"
    case yogaMats = "yoga_mats"
    case foamRollers = "foam_rollers"
    
    var displayName: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var icon: String {
        "dumbbell.fill"
    }
}

struct OpeningHours: Codable {
    var monday: DayHours?
    var tuesday: DayHours?
    var wednesday: DayHours?
    var thursday: DayHours?
    var friday: DayHours?
    var saturday: DayHours?
    var sunday: DayHours?
    
    struct DayHours: Codable {
        var open: String // Format: "HH:mm"
        var close: String // Format: "HH:mm"
        var isClosed: Bool
        
        enum CodingKeys: String, CodingKey {
            case open
            case close
            case isClosed = "is_closed"
        }
    }
}

