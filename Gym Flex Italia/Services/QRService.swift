//
//  QRService.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/14/25.
//

import Foundation
import UIKit
import CoreImage

/// QR code generation and scanning service
final class QRService {
    
    static let shared = QRService()
    
    private init() {}
    
    // MARK: - QR Code Generation
    func generateQRCode(from string: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let qrImage = qrFilter.outputImage else {
            return nil
        }
        
        // Scale the QR code to desired size
        let scaleX = size.width / qrImage.extent.size.width
        let scaleY = size.height / qrImage.extent.size.height
        let transformedImage = qrImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - QR Code with Logo
    func generateQRCodeWithLogo(from string: String, 
                                logo: UIImage? = nil,
                                size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let qrImage = generateQRCode(from: string, size: size) else {
            return nil
        }
        
        guard let logo = logo else {
            return qrImage
        }
        
        // Create a composite image with QR code and logo in center
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Draw QR code
            qrImage.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw logo in center
            let logoSize = CGSize(width: size.width * 0.25, height: size.height * 0.25)
            let logoOrigin = CGPoint(
                x: (size.width - logoSize.width) / 2,
                y: (size.height - logoSize.height) / 2
            )
            
            // Draw white background for logo
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(
                origin: logoOrigin,
                size: logoSize
            ))
            
            // Draw logo
            logo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        }
    }
    
    // MARK: - Booking QR Code
    func generateBookingQRCode(booking: Booking, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard let qrData = booking.qrCodeData else {
            return nil
        }
        return generateQRCode(from: qrData, size: size)
    }
    
    // MARK: - QR Code Data Model
    struct QRCodeData: Codable {
        let bookingId: String
        let userId: String
        let gymId: String
        let timestamp: Date
        let expiresAt: Date
        
        var isExpired: Bool {
            Date() > expiresAt
        }
        
        var isValid: Bool {
            !isExpired && timestamp <= Date()
        }
        
        func encode() -> String? {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(self),
                  let jsonString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return jsonString.data(using: .utf8)?.base64EncodedString()
        }
        
        static func decode(from string: String) -> QRCodeData? {
            guard let data = Data(base64Encoded: string) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(QRCodeData.self, from: data)
        }
    }
}

