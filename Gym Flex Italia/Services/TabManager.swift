//
//  TabManager.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/21/25.
//

import Foundation
import SwiftUI
import Combine

/// Manages the root tab selection and navigation
final class TabManager: ObservableObject {
    @Published var selectedTab: RootTabView.Tab = .home
    
    static let shared = TabManager()
    
    private init() {}
    
    func switchTo(_ tab: RootTabView.Tab) {
        withAnimation {
            selectedTab = tab
        }
    }
}
