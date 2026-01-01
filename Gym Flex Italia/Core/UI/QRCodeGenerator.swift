//
//  QRCodeGenerator.swift
//  Gym Flex Italia
//
//  Utility for generating QR code images from text using CoreImage.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Utility class for generating QR code images
enum QRCodeGenerator {
    
    /// Generates a SwiftUI Image from a text string
    /// - Parameters:
    ///   - text: The text to encode in the QR code
    ///   - scale: Scale factor for the output (default 10x for crisp display)
    /// - Returns: A SwiftUI Image, or nil if generation fails
    static func makeImage(from text: String, scale: CGFloat = 10) -> Image? {
        guard let uiImage = makeUIImage(from: text, scale: scale) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    
    /// Generates a UIImage from a text string
    /// - Parameters:
    ///   - text: The text to encode in the QR code
    ///   - scale: Scale factor for the output
    /// - Returns: A UIImage, or nil if generation fails
    static func makeUIImage(from text: String, scale: CGFloat = 10) -> UIImage? {
        // Convert text to data
        let data = Data(text.utf8)
        
        // Create QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        // Get the output CIImage
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        // Scale the image for crisp display
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        // Convert to CGImage then UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Generates a QR code image for a booking's check-in payload
    /// - Parameter booking: The booking to generate a QR code for
    /// - Returns: A SwiftUI Image containing the QR code
    static func makeCheckInQRImage(for booking: Booking) -> Image? {
        let payload = CheckInQRPayload.make(from: booking)
        let qrString = payload.toQRCodeString()
        return makeImage(from: qrString)
    }
}
