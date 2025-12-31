//
//  AppContainerKey.swift
//  Gym Flex Italia
//
//  SwiftUI Environment integration for AppContainer
//

import SwiftUI

/// Environment key for accessing AppContainer from SwiftUI views
private struct AppContainerKey: EnvironmentKey {
    /// Default value uses the demo container
    static let defaultValue: AppContainer = .demo()
}

/// Extension to add appContainer to SwiftUI's EnvironmentValues
extension EnvironmentValues {
    /// The app's dependency injection container
    /// Access in views via: @Environment(\.appContainer) var appContainer
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
