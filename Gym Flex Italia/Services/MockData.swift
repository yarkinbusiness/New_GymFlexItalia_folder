//
//  MockData.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/21/25.
//

import Foundation
import CoreLocation

struct MockData {
    
    // MARK: - Sample Gyms
    static let sampleGyms: [Gym] = [
        Gym(
            id: "gym_001",
            name: "Flex Gym Roma Termini",
            description: "Premium fitness center located right next to Termini station. Features state-of-the-art Technogym equipment, a large free weights area, and a dedicated cardio zone. Perfect for travelers and locals alike.",
            address: "Via Giovanni Giolitti 44",
            city: "Roma",
            region: "Lazio",
            postalCode: "00185",
            country: "Italy",
            latitude: 41.9009,
            longitude: 12.5020,
            pricePerHour: 8.50,
            currency: "EUR",
            coverImageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
            imageURLs: [
                "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
                "https://images.unsplash.com/photo-1571902943202-507ec2618e8f?q=80&w=1375&auto=format&fit=crop"
            ],
            amenities: [.wifi, .showers, .lockers, .airConditioning, .waterStation],
            equipment: [.treadmills, .dumbbells, .barbells, .benchPress, .squatRack],
            workoutTypes: [.cardio, .strength, .hiit],
            phoneNumber: "+39 06 12345678",
            email: "info@flexgymroma.it",
            website: "https://flexgymroma.it",
            openingHours: nil,
            rating: 4.8,
            reviewCount: 124,
            totalBookings: 1250,
            isActive: true,
            isVerified: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Gym(
            id: "gym_002",
            name: "Urban Fitness Milano",
            description: "Modern industrial-style gym in the heart of Milan. Offers functional training zones, yoga classes, and a sauna for post-workout recovery.",
            address: "Corso Como 10",
            city: "Milano",
            region: "Lombardia",
            postalCode: "20154",
            country: "Italy",
            latitude: 45.4809,
            longitude: 9.1889,
            pricePerHour: 12.00,
            currency: "EUR",
            coverImageURL: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1470&auto=format&fit=crop",
            imageURLs: [
                "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1470&auto=format&fit=crop",
                "https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=1469&auto=format&fit=crop"
            ],
            amenities: [.wifi, .showers, .lockers, .sauna, .towelService],
            equipment: [.kettlebells, .pullUpBar, .yogaMats, .foamRollers],
            workoutTypes: [.yoga, .pilates],
            phoneNumber: nil,
            email: nil,
            website: nil,
            openingHours: nil,
            rating: 4.9,
            reviewCount: 89,
            totalBookings: 850,
            isActive: true,
            isVerified: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Gym(
            id: "gym_003",
            name: "CrossFit Colosseum",
            description: "Hardcore CrossFit box for serious athletes. Equipped with rogue rigs, bumper plates, and rowing machines. Drop-ins welcome.",
            address: "Via del Colosseo 2",
            city: "Roma",
            region: "Lazio",
            postalCode: "00184",
            country: "Italy",
            latitude: 41.8902,
            longitude: 12.4922,
            pricePerHour: 15.00,
            currency: "EUR",
            coverImageURL: "https://images.unsplash.com/photo-1517963879466-e1b54ebd9930?q=80&w=1470&auto=format&fit=crop",
            imageURLs: [
                "https://images.unsplash.com/photo-1517963879466-e1b54ebd9930?q=80&w=1470&auto=format&fit=crop",
                "https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?q=80&w=1470&auto=format&fit=crop"
            ],
            amenities: [.showers, .lockers, .waterStation],
            equipment: [.rowingMachine, .barbells, .pullUpBar, .battlingRopes],
            workoutTypes: [.crossfit, .strength],
            phoneNumber: nil,
            email: nil,
            website: nil,
            openingHours: nil,
            rating: 4.7,
            reviewCount: 210,
            totalBookings: 3200,
            isActive: true,
            isVerified: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Gym(
            id: "gym_004",
            name: "Wellness Point Florence",
            description: "A holistic wellness center offering a calm environment for your workout. Includes a swimming pool and spa access.",
            address: "Piazza della Signoria 5",
            city: "Firenze",
            region: "Toscana",
            postalCode: "50122",
            country: "Italy",
            latitude: 43.7696,
            longitude: 11.2558,
            pricePerHour: 18.00,
            currency: "EUR",
            coverImageURL: "https://images.unsplash.com/photo-1576678927484-cc907957088c?q=80&w=1374&auto=format&fit=crop",
            imageURLs: [
                "https://images.unsplash.com/photo-1576678927484-cc907957088c?q=80&w=1374&auto=format&fit=crop",
                "https://images.unsplash.com/photo-1560090995-01632a28895b?q=80&w=1469&auto=format&fit=crop"
            ],
            amenities: [.wifi, .showers, .lockers, .pool, .sauna],
            equipment: [.ellipticals, .yogaMats],
            workoutTypes: [.swimming, .cardio, .yoga],
            phoneNumber: nil,
            email: nil,
            website: nil,
            openingHours: nil,
            rating: 4.6,
            reviewCount: 56,
            totalBookings: 400,
            isActive: false,
            isVerified: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    // MARK: - Sample Bookings
    static var sampleBookings: [Booking] = [
        Booking(
            id: "booking_001",
            userId: "user_123",
            gymId: "gym_001",
            gymName: "Flex Gym Roma Termini",
            gymAddress: "Via Giovanni Giolitti 44, 00185 Roma",
            gymCoverImageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop",
            startTime: Date(), // Now
            endTime: Date().addingTimeInterval(3600), // 1 hour later
            duration: 60,
            pricePerHour: 8.50,
            totalPrice: 8.50,
            currency: "EUR",
            status: .completed,
            checkinCode: nil,
            checkinTime: nil,
            checkoutTime: nil,
            qrCodeData: "mock_qr_001",
            qrCodeExpiresAt: nil,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date(),
            cancelledAt: nil,
            cancellationReason: nil
        ),
        Booking(
            id: "booking_002",
            userId: "user_123",
            gymId: "gym_002",
            gymName: "Urban Fitness Milano",
            gymAddress: "Corso Como 10, 20154 Milano",
            gymCoverImageURL: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1470&auto=format&fit=crop",
            startTime: Date().addingTimeInterval(-3600 * 48), // 2 days ago
            endTime: Date().addingTimeInterval(-3600 * 46.5),
            duration: 90,
            pricePerHour: 12.00,
            totalPrice: 18.00,
            currency: "EUR",
            status: .completed,
            checkinCode: nil,
            checkinTime: Date().addingTimeInterval(-3600 * 48),
            checkoutTime: Date().addingTimeInterval(-3600 * 46.5),
            qrCodeData: "mock_qr_002",
            qrCodeExpiresAt: nil,
            createdAt: Date().addingTimeInterval(-3600 * 50),
            updatedAt: Date(),
            cancelledAt: nil,
            cancellationReason: nil
        )
    ]
    
    // MARK: - Sample Availability
    static func getAvailability(for date: Date, gymId: String) -> [AvailabilitySlot] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        var slots: [AvailabilitySlot] = []
        
        // Generate slots from 6 AM to 10 PM
        for hour in 6...22 {
            if let slotDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay) {
                let isAvailable = Int.random(in: 0...10) > 2 // 80% chance available
                let booked = Int.random(in: 0...20)
                let capacity = 50
                
                slots.append(AvailabilitySlot(
                    id: "slot_\(gymId)_\(hour)",
                    gymId: gymId,
                    startTime: slotDate,
                    endTime: calendar.date(byAdding: .hour, value: 1, to: slotDate)!,
                    isAvailable: isAvailable,
                    bookedSlots: booked,
                    maxCapacity: capacity
                ))
            }
        }
        
        return slots
    }
}
