//
//  DeepLinkQueue.swift
//  Gym Flex Italia
//
//  Buffers deep links for deferred processing (e.g., cold start from notification)
//

import Foundation
import Combine

/// Queue for buffering deep links until the UI is ready to consume them
/// Used for cold start scenarios where notifications arrive before the router is ready
final class DeepLinkQueue: ObservableObject {
    
    // MARK: - Published State
    
    /// Pending deep links waiting to be processed
    @Published private(set) var pending: [DeepLink] = []
    
    // MARK: - Queue Operations
    
    /// Adds a deep link to the queue
    /// - Parameter link: The deep link to enqueue
    func enqueue(_ link: DeepLink) {
        DemoTapLogger.log("DeepLinkQueue.Enqueue", context: "\(link)")
        pending.append(link)
    }
    
    /// Removes and returns the next deep link from the queue
    /// - Returns: The next deep link, or nil if queue is empty
    func dequeue() -> DeepLink? {
        guard !pending.isEmpty else { return nil }
        let link = pending.removeFirst()
        DemoTapLogger.log("DeepLinkQueue.Dequeue", context: "\(link)")
        return link
    }
    
    /// Clears all pending deep links
    func clear() {
        DemoTapLogger.log("DeepLinkQueue.Clear", context: "count: \(pending.count)")
        pending.removeAll()
    }
    
    /// Whether there are pending deep links
    var hasPending: Bool {
        !pending.isEmpty
    }
    
    /// Number of pending deep links
    var count: Int {
        pending.count
    }
}

