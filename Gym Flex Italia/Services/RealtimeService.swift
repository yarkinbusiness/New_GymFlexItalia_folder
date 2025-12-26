//
//  RealtimeService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import Combine

/// Realtime service for Supabase realtime channels (Phase 2)
final class RealtimeService: ObservableObject {
    
    static let shared = RealtimeService()
    
    @Published var isConnected = false
    @Published var connectionError: Error?
    
    private var websocket: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    
    // Message handlers
    private var messageHandlers: [String: (Message) -> Void] = [:]
    private var bookingHandlers: [String: (Booking) -> Void] = [:]
    private var profileHandlers: [(Profile) -> Void] = []
    
    private init() {}
    
    // MARK: - Connection Management
    func connect(token: String) {
        guard websocket == nil else { return }
        
        let url = URL(string: "\(AppConfig.API.supabaseURL)/realtime/v1/websocket")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession(configuration: .default)
        websocket = session.webSocketTask(with: request)
        websocket?.resume()
        
        isConnected = true
        receiveMessage()
    }
    
    func disconnect() {
        websocket?.cancel(with: .goingAway, reason: nil)
        websocket = nil
        isConnected = false
        messageHandlers.removeAll()
        bookingHandlers.removeAll()
        profileHandlers.removeAll()
    }
    
    // MARK: - Receive Messages
    private func receiveMessage() {
        websocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue listening
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.connectionError = error
                self?.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleDataMessage(data)
        @unknown default:
            break
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        handleDataMessage(data)
    }
    
    private func handleDataMessage(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Try to decode as different message types
            if let chatMessage = try? decoder.decode(RealtimeMessage<Message>.self, from: data) {
                handleChatMessage(chatMessage.payload)
            } else if let bookingUpdate = try? decoder.decode(RealtimeMessage<Booking>.self, from: data) {
                handleBookingUpdate(bookingUpdate.payload)
            } else if let profileUpdate = try? decoder.decode(RealtimeMessage<Profile>.self, from: data) {
                handleProfileUpdate(profileUpdate.payload)
            }
        }
    }
    
    // MARK: - Subscribe to Channels
    func subscribeToGroupChat(groupId: String, handler: @escaping (Message) -> Void) {
        messageHandlers[groupId] = handler
        
        let subscribeMessage = RealtimeSubscribe(
            event: "phx_join",
            topic: "realtime:public:messages:group_id=eq.\(groupId)",
            payload: [:],
            ref: UUID().uuidString
        )
        
        sendMessage(subscribeMessage)
    }
    
    func unsubscribeFromGroupChat(groupId: String) {
        messageHandlers.removeValue(forKey: groupId)
        
        let unsubscribeMessage = RealtimeSubscribe(
            event: "phx_leave",
            topic: "realtime:public:messages:group_id=eq.\(groupId)",
            payload: [:],
            ref: UUID().uuidString
        )
        
        sendMessage(unsubscribeMessage)
    }
    
    func subscribeToBookingUpdates(bookingId: String, handler: @escaping (Booking) -> Void) {
        bookingHandlers[bookingId] = handler
        
        let subscribeMessage = RealtimeSubscribe(
            event: "phx_join",
            topic: "realtime:public:bookings:id=eq.\(bookingId)",
            payload: [:],
            ref: UUID().uuidString
        )
        
        sendMessage(subscribeMessage)
    }
    
    func subscribeToProfileUpdates(handler: @escaping (Profile) -> Void) {
        profileHandlers.append(handler)
        
        let subscribeMessage = RealtimeSubscribe(
            event: "phx_join",
            topic: "realtime:public:profiles",
            payload: [:],
            ref: UUID().uuidString
        )
        
        sendMessage(subscribeMessage)
    }
    
    // MARK: - Message Handlers
    private func handleChatMessage(_ message: Message) {
        if let handler = messageHandlers[message.groupId] {
            DispatchQueue.main.async {
                handler(message)
            }
        }
    }
    
    private func handleBookingUpdate(_ booking: Booking) {
        if let handler = bookingHandlers[booking.id] {
            DispatchQueue.main.async {
                handler(booking)
            }
        }
    }
    
    private func handleProfileUpdate(_ profile: Profile) {
        DispatchQueue.main.async {
            self.profileHandlers.forEach { $0(profile) }
        }
    }
    
    // MARK: - Send Message
    private func sendMessage<T: Encodable>(_ message: T) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(message)
            guard let string = String(data: data, encoding: .utf8) else { return }
            
            websocket?.send(.string(string)) { error in
                if let error = error {
                    print("Failed to send message: \(error)")
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }
    
    // MARK: - Heartbeat (Keep-alive)
    func startHeartbeat() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sendHeartbeat()
            }
            .store(in: &cancellables)
    }
    
    private func sendHeartbeat() {
        let heartbeat = RealtimeSubscribe(
            event: "heartbeat",
            topic: "phoenix",
            payload: [:],
            ref: UUID().uuidString
        )
        sendMessage(heartbeat)
    }
}

// MARK: - Realtime Message Types
struct RealtimeMessage<T: Codable>: Codable {
    let event: String
    let topic: String
    let payload: T
    let ref: String?
}

struct RealtimeSubscribe: Codable {
    let event: String
    let topic: String
    let payload: [String: String]
    let ref: String
}

