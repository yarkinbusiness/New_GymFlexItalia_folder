//
//  ImageCacheService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import UIKit
import Combine

/// Image caching service for efficient image loading
final class ImageCacheService {
    
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configure cache
        cache.totalCostLimit = AppConfig.Cache.imageCacheSize
        cache.countLimit = 200
        
        // Set up disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Memory Cache
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: imageCost(image))
        
        // Also save to disk cache
        Task {
            await saveToDisk(image, forKey: key)
        }
    }
    
    // MARK: - Disk Cache
    private func diskCacheURL(forKey key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    private func saveToDisk(_ image: UIImage, forKey key: String) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let url = diskCacheURL(forKey: key)
        
        try? data.write(to: url)
    }
    
    private func loadFromDisk(forKey key: String) async -> UIImage? {
        let url = diskCacheURL(forKey: key)
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Add to memory cache
        await MainActor.run {
            cache.setObject(image, forKey: key as NSString)
        }
        
        return image
    }
    
    // MARK: - Load Image
    func loadImage(from urlString: String) async -> UIImage? {
        // Check memory cache
        if let cachedImage = getImage(forKey: urlString) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await loadFromDisk(forKey: urlString) {
            return diskImage
        }
        
        // Download from network
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                return nil
            }
            
            // Cache the image
            await MainActor.run {
                setImage(image, forKey: urlString)
            }
            
            return image
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear Cache
    func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    func clearDiskCache() async {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
    
    func clearAllCache() async {
        clearMemoryCache()
        await clearDiskCache()
    }
    
    // MARK: - Cache Size
    func getCacheSize() async -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return totalSize
    }
    
    // MARK: - Helper Methods
    private func imageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let cost = cgImage.width * cgImage.height * bytesPerPixel
        return cost
    }
}

// MARK: - Async Image Loader (SwiftUI Helper)
@MainActor
final class AsyncImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let imageCache = ImageCacheService.shared
    
    func load(from urlString: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                if let loadedImage = await imageCache.loadImage(from: urlString) {
                    self.image = loadedImage
                } else {
                    self.error = ImageLoadError.loadFailed
                }
            }
            self.isLoading = false
        }
    }
    
    func cancel() {
        // Cancel any ongoing tasks if needed
    }
}

enum ImageLoadError: LocalizedError {
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load image"
        }
    }
}

