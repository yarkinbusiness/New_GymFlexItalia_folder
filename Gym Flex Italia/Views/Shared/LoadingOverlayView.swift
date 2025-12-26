//
//  LoadingOverlayView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import SwiftUI

/// Full-screen loading overlay
struct LoadingOverlayView: View {
    
    var message: String = "Loading..."
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

/// Inline loading view
struct InlineLoadingView: View {
    
    var message: String = "Loading..."
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        
        VStack {
            Text("Content behind overlay")
                .font(.title)
            
            Spacer()
            
            InlineLoadingView(message: "Fetching data...")
                .background(Color.white)
                .cornerRadius(12)
                .padding()
        }
        
        LoadingOverlayView(message: "Please wait...")
    }
}

