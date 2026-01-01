//
//  ShareSheet.swift
//  Gym Flex Italia
//
//  SwiftUI wrapper for UIActivityViewController.
//  Used for sharing invite links and content.
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    
    /// Items to share (URLs, strings, images, etc.)
    let activityItems: [Any]
    
    /// Optional application activities
    var applicationActivities: [UIActivity]? = nil
    
    /// Optional excluded activity types
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    /// Completion handler
    var onComplete: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        controller.excludedActivityTypes = excludedActivityTypes
        
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            onComplete?(activityType, completed, returnedItems, error)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Convenience Initializers

extension ShareSheet {
    
    /// Create a share sheet with a single URL
    init(url: URL, onComplete: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil) {
        self.activityItems = [url]
        self.onComplete = onComplete
    }
    
    /// Create a share sheet with text
    init(text: String, onComplete: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil) {
        self.activityItems = [text]
        self.onComplete = onComplete
    }
    
    /// Create a share sheet with text and URL
    init(text: String, url: URL, onComplete: ((UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void)? = nil) {
        self.activityItems = [text, url]
        self.onComplete = onComplete
    }
}

#Preview {
    ShareSheet(text: "Check out GymFlex!")
}
