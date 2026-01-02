//
//  FAQStore.swift
//  Gym Flex Italia
//
//  Static store for FAQ items.
//

import Foundation

/// Static store for FAQ items
struct FAQStore {
    
    /// Shared instance
    static let shared = FAQStore()
    
    /// FAQ version for tracking updates
    static let version = "1.0"
    
    /// All FAQ items
    let items: [FAQItem] = [
        FAQItem(
            id: "faq_booking",
            question: "How do I book a gym session?",
            answer: "Navigate to the Discover tab, find a gym near you, and tap on it to view details. Select your preferred time slot and tap 'Book Now'. The session cost will be deducted from your wallet balance."
        ),
        FAQItem(
            id: "faq_wallet",
            question: "How do I add money to my wallet?",
            answer: "Go to your Profile tab, tap on 'Wallet', then tap 'Top Up'. Choose an amount and complete the payment. Your balance will be updated immediately."
        ),
        FAQItem(
            id: "faq_cancel",
            question: "Can I cancel a booking?",
            answer: "Yes, you can cancel a booking up to 2 hours before the session starts. Go to your bookings, select the session, and tap 'Cancel'. Refunds are processed according to our cancellation policy."
        ),
        FAQItem(
            id: "faq_checkin",
            question: "How do I check in at the gym?",
            answer: "When you arrive at the gym, open the Check-in tab and scan the QR code at the entrance. Alternatively, show your booking confirmation to the staff."
        ),
        FAQItem(
            id: "faq_extend",
            question: "Can I extend my session?",
            answer: "Yes, if the gym has availability, you can extend your session from the Check-in tab while your session is active. Additional time will be charged at the standard rate."
        ),
        FAQItem(
            id: "faq_groups",
            question: "What are Groups?",
            answer: "Groups allow you to connect with other gym-goers, share workout tips, and coordinate gym sessions together. Join existing groups or create your own from the Groups tab."
        ),
        FAQItem(
            id: "faq_payment",
            question: "What payment methods are accepted?",
            answer: "We accept major credit and debit cards (Visa, Mastercard, American Express) as well as Apple Pay. You can manage your payment methods in Profile → Payment Methods."
        ),
        FAQItem(
            id: "faq_refund",
            question: "How do refunds work?",
            answer: "When you cancel a booking or receive a refund, the amount is credited back to your GymFlex wallet. Wallet-to-bank refunds can be requested through the app settings."
        ),
        FAQItem(
            id: "faq_locations",
            question: "How do I find gyms near me?",
            answer: "Enable location services for GymFlex, then open the Discover tab. Nearby gyms will automatically appear based on your location. You can also search by name or filter by amenities."
        ),
        FAQItem(
            id: "faq_notifications",
            question: "How do I manage notifications?",
            answer: "Go to Profile → Notifications & Preferences. You can enable or disable different notification types like workout reminders, booking updates, and wallet activity alerts."
        ),
        FAQItem(
            id: "faq_account",
            question: "How do I update my profile information?",
            answer: "Tap your profile picture or go to Profile → Edit Profile. Here you can update your name, email, phone number, and fitness goals."
        ),
        FAQItem(
            id: "faq_security",
            question: "How do I enable Face ID/Touch ID?",
            answer: "Go to Profile → Account & Security. Toggle on 'Enable Face ID' (or Touch ID). You can also require biometric authentication on app launch for added security."
        )
    ]
    
    private init() {}
}
