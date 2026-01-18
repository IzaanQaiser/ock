//
//  ScreenshotService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import AppKit
import ScreenCaptureKit

/// Service to capture screenshots on demand
class ScreenshotService {
    static let shared = ScreenshotService()
    
    private init() {}
    
    /// Capture the entire screen and return as JPEG data
    /// Will throw an error if permission is not granted
    func captureScreen() async throws -> Data {
        // Get the main display - this may trigger permission dialog on first run
        let content = try await SCShareableContent.current
        
        guard let display = content.displays.first else {
            throw ScreenshotError.noDisplayFound
        }
        
        // Configure the capture
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let config = SCStreamConfiguration()
        config.width = Int(display.width)
        config.height = Int(display.height)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = true
        
        // Capture a single frame
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
        
        // Convert CGImage to JPEG data
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw ScreenshotError.conversionFailed
        }
        
        return jpegData
    }
    
    /// Capture screen and return as base64 string
    func captureScreenAsBase64() async throws -> String {
        let data = try await captureScreen()
        return data.base64EncodedString()
    }
}

enum ScreenshotError: Error, LocalizedError {
    case noDisplayFound
    case captureFailed
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .noDisplayFound:
            return "No display found for capture"
        case .captureFailed:
            return "Failed to capture screen"
        case .conversionFailed:
            return "Failed to convert image to JPEG"
        }
    }
}
