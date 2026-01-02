//
//  PaymentMethodsStore.swift
//  Gym Flex Italia
//
//  Persisted store for payment methods (mock implementation).
//  Stores to UserDefaults for persistence across app launches.
//

import Foundation
import Combine

/// Persisted store for payment methods
@MainActor
final class PaymentMethodsStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PaymentMethodsStore()
    
    // MARK: - Persistence
    
    private static let persistenceKey = "payment_methods_store_v1"
    
    // MARK: - Published State
    
    /// All saved payment methods
    @Published private(set) var methods: [PaymentMethodItem] = []
    
    // MARK: - Computed Properties
    
    /// Only card payment methods
    var cards: [PaymentMethodItem] {
        methods.filter { $0.kind == .card }
    }
    
    /// The default payment method (if any)
    var defaultMethod: PaymentMethodItem? {
        methods.first { $0.isDefault }
    }
    
    /// Whether there are any saved cards
    var hasCards: Bool {
        !cards.isEmpty
    }
    
    // MARK: - Initialization
    
    private init() {
        load()
        #if DEBUG
        print("💳 PaymentMethodsStore.init: Loaded \(methods.count) payment methods")
        #endif
    }
    
    // MARK: - Persistence
    
    /// Load payment methods from UserDefaults
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.persistenceKey) else {
            #if DEBUG
            print("💳 PaymentMethodsStore.load: No persisted data")
            #endif
            return
        }
        
        do {
            methods = try JSONDecoder().decode([PaymentMethodItem].self, from: data)
            #if DEBUG
            print("💳 PaymentMethodsStore.load: Loaded \(methods.count) methods")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ PaymentMethodsStore.load: Failed to decode: \(error)")
            #endif
        }
    }
    
    /// Save payment methods to UserDefaults
    private func save() {
        do {
            let data = try JSONEncoder().encode(methods)
            UserDefaults.standard.set(data, forKey: Self.persistenceKey)
            #if DEBUG
            print("💳 PaymentMethodsStore.save: Saved \(methods.count) methods")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ PaymentMethodsStore.save: Failed to encode: \(error)")
            #endif
        }
    }
    
    // MARK: - Mutations
    
    /// Add or update a payment method
    func upsert(_ item: PaymentMethodItem) {
        if let index = methods.firstIndex(where: { $0.id == item.id }) {
            methods[index] = item
            #if DEBUG
            print("💳 PaymentMethodsStore.upsert: Updated \(item.displayName)")
            #endif
        } else {
            methods.append(item)
            #if DEBUG
            print("💳 PaymentMethodsStore.upsert: Added \(item.displayName)")
            #endif
        }
        
        // If this is set as default, unset others
        if item.isDefault {
            setDefaultInternal(id: item.id)
        }
        
        save()
    }
    
    /// Remove a payment method by ID
    func remove(id: String) {
        guard let index = methods.firstIndex(where: { $0.id == id }) else {
            #if DEBUG
            print("⚠️ PaymentMethodsStore.remove: Method \(id) not found")
            #endif
            return
        }
        
        let removed = methods.remove(at: index)
        #if DEBUG
        print("💳 PaymentMethodsStore.remove: Removed \(removed.displayName)")
        #endif
        
        // If removed was default and there are remaining cards, set first card as default
        if removed.isDefault && !cards.isEmpty {
            if let firstCard = cards.first {
                setDefaultInternal(id: firstCard.id)
            }
        }
        
        save()
    }
    
    /// Set a payment method as default
    func setDefault(id: String) {
        setDefaultInternal(id: id)
        save()
    }
    
    /// Internal helper to set default without saving
    private func setDefaultInternal(id: String) {
        for i in methods.indices {
            methods[i].isDefault = (methods[i].id == id)
        }
        #if DEBUG
        print("💳 PaymentMethodsStore.setDefault: Set \(id) as default")
        #endif
    }
    
    // MARK: - Reset
    
    /// Reset store (for testing/debugging)
    func reset() {
        methods = []
        save()
        #if DEBUG
        print("💳 PaymentMethodsStore.reset: Cleared all methods")
        #endif
    }
}
