//
//  ScreenshotCapture.swift
//  Ock-Cursor
//
//  Created on 2024
//

import AppKit
import Foundation
import ScreenCaptureKit
import CoreMedia
import CoreVideo
import Combine

class ScreenshotCapture: ObservableObject {
    static let shared = ScreenshotCapture()
    
    private var isCapturing = false // Prevent multiple simultaneous captures
    @Published var hasPermission: Bool = false
    
    private init() {}
    
    /// Check and request screen recording permission
    /// This should be called on app startup
    func checkAndRequestPermission() async {
        print("📸 ScreenshotCapture: Checking screen recording permission...")
        print("   - Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        print("   - App name: \(Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "unknown")")
        print("   - Executable path: \(Bundle.main.executablePath ?? "unknown")")
        
        // First attempt - this will trigger permission dialog if needed
        do {
            print("📸 ScreenshotCapture: Attempting to get shareable content (first attempt)...")
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            await MainActor.run {
                self.hasPermission = true
            }
            
            print("✅ ScreenshotCapture: Screen recording permission GRANTED")
            print("   - Number of displays: \(content.displays.count)")
            print("   - Number of windows: \(content.windows.count)")
            if let firstDisplay = content.displays.first {
                print("   - First display: ID=\(firstDisplay.displayID), size=\(firstDisplay.width)x\(firstDisplay.height)")
            }
            return
        } catch {
            let errorDescription = error.localizedDescription
            let nsError = error as NSError
            print("⚠️ ScreenshotCapture: First attempt failed")
            print("   - Error domain: \(nsError.domain)")
            print("   - Error code: \(nsError.code)")
            print("   - Error description: \(errorDescription)")
            print("   - Full error: \(error)")
            
            // If it says "declined", wait and retry (user might have just granted it)
            if errorDescription.contains("declined") || errorDescription.contains("TCC") {
                print("📸 ScreenshotCapture: Permission shows as 'declined'")
                print("   - This might be cached - waiting 3 seconds and retrying...")
                print("   - If you just granted permission, it should work on retry")
                
                // Wait longer for system to update permission status
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                
                // Retry once
                print("📸 ScreenshotCapture: Retrying permission check...")
                do {
                    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    
                    await MainActor.run {
                        self.hasPermission = true
                    }
                    
                    print("✅ ScreenshotCapture: Screen recording permission GRANTED (on retry)")
                    print("   - Number of displays: \(content.displays.count)")
                    print("   - Number of windows: \(content.windows.count)")
                    return
                } catch {
                    let retryError = error.localizedDescription
                    print("❌ ScreenshotCapture: Still denied after retry")
                    print("   - Retry error: \(retryError)")
                    print("   - NOTE: If you just granted permission, you may need to RESTART THE APP")
                    print("   - macOS sometimes requires an app restart after granting permission")
                    
                    await MainActor.run {
                        self.hasPermission = false
                    }
                    
                    // Open System Settings
                    print("📸 ScreenshotCapture: Opening System Settings...")
                    print("   - Please enable 'ock' (or the app name shown) in Privacy & Security > Screen Recording")
                    print("   - Then RESTART THE APP for the permission to take effect")
                    DispatchQueue.main.async {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    return
                }
            } else {
                // Other error (not permission-related)
                await MainActor.run {
                    self.hasPermission = false
                }
                print("❌ ScreenshotCapture: Error checking permission: \(errorDescription)")
            }
        }
    }
    
    
    /// Capture a screenshot of the main screen using ScreenCaptureKit
    /// - Returns: Screenshot as NSImage, or nil if capture fails
    func captureScreen() async -> NSImage? {
        print("📸 ScreenshotCapture: captureScreen() called")
        
        // Prevent multiple simultaneous captures
        guard !isCapturing else {
            print("⚠️ ScreenshotCapture: Already capturing, skipping duplicate request")
            return nil
        }
        
        isCapturing = true
        defer { 
            isCapturing = false
            print("📸 ScreenshotCapture: isCapturing set to false")
        }
        
        print("📸 ScreenshotCapture: Attempting to get shareable content...")
        
        // Try to get shareable content - this will trigger permission dialog if needed
        var content: SCShareableContent?
        
        // Single attempt - if permission is granted, this will succeed
        // If not granted, it will fail and we'll return nil (user can try again)
        do {
            print("📸 ScreenshotCapture: Calling SCShareableContent.excludingDesktopWindows...")
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            print("✅ ScreenshotCapture: Successfully got shareable content")
            print("   - Number of displays: \(content?.displays.count ?? 0)")
            print("   - Number of windows: \(content?.windows.count ?? 0)")
        } catch {
            let errorDescription = error.localizedDescription
            print("❌ ScreenshotCapture: Failed to get shareable content")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(errorDescription)")
            print("   - Error localizedDescription: \(error.localizedDescription)")
            
            // Check if it's a permission error
            if errorDescription.contains("declined") || errorDescription.contains("permission") || errorDescription.contains("denied") || errorDescription.contains("not authorized") || errorDescription.contains("TCC") {
                print("   📸 SCREEN RECORDING PERMISSION DENIED")
                print("   - The permission dialog was declined or permission was previously denied")
                print("   - Opening System Settings to enable screen recording permission...")
                
                // Open System Settings to Screen Recording permission page
                DispatchQueue.main.async {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                print("   - Please enable 'ock' in System Settings > Privacy & Security > Screen Recording")
                print("   - Then try sending a message again")
            }
            return nil
        }
        
        guard let content = content else {
            print("❌ ScreenshotCapture: Content is nil after successful call")
            return nil
        }
        
        print("📸 ScreenshotCapture: Got content, finding main display...")
        
        do {
            // Get main screen info
            guard let mainScreen = NSScreen.main else {
                print("❌ ScreenshotCapture: Could not get NSScreen.main")
                return nil
            }
            
            let mainScreenID = mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            print("📸 ScreenshotCapture: Main screen ID: \(mainScreenID?.description ?? "nil")")
            print("📸 ScreenshotCapture: Available displays: \(content.displays.map { "\($0.displayID)" }.joined(separator: ", "))")
            
            guard let mainDisplay = content.displays.first(where: { $0.displayID == mainScreenID }) ?? content.displays.first else {
                print("⚠️ ScreenshotCapture: Could not find main display")
                print("   - Available display IDs: \(content.displays.map { "\($0.displayID)" }.joined(separator: ", "))")
                return nil
            }
            
            print("✅ ScreenshotCapture: Found main display")
            print("   - Display ID: \(mainDisplay.displayID)")
            print("   - Display size: \(mainDisplay.width) x \(mainDisplay.height)")
            
            // Create content filter
            print("📸 ScreenshotCapture: Creating content filter...")
            let filter = SCContentFilter(display: mainDisplay, excludingWindows: [])
            
            // Create stream configuration
            print("📸 ScreenshotCapture: Creating stream configuration...")
            let config = SCStreamConfiguration()
            // Reduce resolution for faster capture (scale down by 50% for speed)
            let scaleFactor: CGFloat = 0.5
            config.width = Int(CGFloat(mainDisplay.width) * scaleFactor)
            config.height = Int(CGFloat(mainDisplay.height) * scaleFactor)
            config.sourceRect = CGRect(x: 0, y: 0, width: mainDisplay.width, height: mainDisplay.height)
            config.showsCursor = false
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 1 FPS is enough for screenshots
            print("   - Config size: \(config.width) x \(config.height) (scaled down from \(Int(mainDisplay.width))x\(Int(mainDisplay.height)))")
            print("   - Source rect: \(config.sourceRect)")
            
            // Create stream output handler
            print("📸 ScreenshotCapture: Creating stream output handler...")
            var capturedImage: NSImage?
            var frameReceived = false
            let semaphore = DispatchSemaphore(value: 0)
            
            let streamOutput = CaptureStreamOutput { sampleBuffer, type in
                print("📸 ScreenshotCapture: Stream output handler called!")
                print("   - Type: \(type)")
                
                // Only process screen frames
                guard type == .screen else {
                    print("⚠️ ScreenshotCapture: Ignoring non-screen frame type: \(type)")
                    return
                }
                
                guard let imageBuffer = sampleBuffer.imageBuffer else {
                    print("⚠️ ScreenshotCapture: Sample buffer has no imageBuffer")
                    if !frameReceived {
                        print("   - Signaling semaphore (no image buffer)")
                        semaphore.signal()
                    }
                    return
                }
                
                print("📸 ScreenshotCapture: Got imageBuffer, converting to NSImage...")
                let width = CVPixelBufferGetWidth(imageBuffer)
                let height = CVPixelBufferGetHeight(imageBuffer)
                print("   - Image buffer size: \(width) x \(height)")
                
                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                let context = CIContext()
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    print("⚠️ ScreenshotCapture: Failed to create CGImage from CIImage")
                    if !frameReceived {
                        print("   - Signaling semaphore (CGImage creation failed)")
                        semaphore.signal()
                    }
                    return
                }
                
                print("📸 ScreenshotCapture: Created CGImage, creating NSImage...")
                capturedImage = NSImage(cgImage: cgImage, size: NSSize(width: CGFloat(width), height: CGFloat(height)))
                frameReceived = true
                print("✅ ScreenshotCapture: Successfully created NSImage from frame")
                print("   - Image size: \(capturedImage?.size ?? .zero)")
                
                // Signal only once
                print("   - Signaling semaphore (frame captured)")
                semaphore.signal()
            }
            
            // Create and start stream
            print("📸 ScreenshotCapture: Creating SCStream...")
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)
            
            print("📸 ScreenshotCapture: Adding stream output...")
            // Use a background queue for sample handling (ScreenCaptureKit requirement)
            let sampleQueue = DispatchQueue(label: "com.ock.screenshot.capture", qos: .userInitiated)
            print("   - Using sample handler queue: background (com.ock.screenshot.capture)")
            print("   - Output type: .screen")
            try stream.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: sampleQueue)
            
            print("📸 ScreenshotCapture: Starting capture...")
            try await stream.startCapture()
            print("✅ ScreenshotCapture: Stream started, waiting for frame...")
            print("   - Waiting up to 3 seconds for first frame...")
            
            // Wait for first frame (reduced timeout for faster capture)
            let timeoutResult = semaphore.wait(timeout: .now() + 3.0)
            print("📸 ScreenshotCapture: Semaphore wait completed")
            print("   - Timeout result: \(timeoutResult == .success ? "success" : "timed out")")
            print("   - Frame received: \(frameReceived)")
            print("   - Captured image: \(capturedImage != nil ? "yes" : "no")")
            
            // Stop capture
            print("📸 ScreenshotCapture: Stopping capture...")
            try await stream.stopCapture()
            print("✅ ScreenshotCapture: Stream stopped")
            
            if let image = capturedImage {
                print("✅ ScreenshotCapture: Screenshot captured successfully")
                print("   - Image size: \(image.size)")
                print("   - Image representation count: \(image.representations.count)")
                return image
            } else {
                print("⚠️ ScreenshotCapture: No image captured")
                print("   - Frame received: \(frameReceived)")
                print("   - Semaphore result: \(timeoutResult == .success ? "success" : "timed out")")
                print("   - Possible issue: Stream output handler not receiving frames")
                return nil
            }
        } catch {
            print("⚠️ ScreenshotCapture: Error in capture process")
            print("   - Error type: \(type(of: error))")
            print("   - Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Capture screenshot and convert to JPEG data
    /// - Parameter compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: JPEG data, or nil if capture fails
    func captureScreenAsJPEG(compressionQuality: CGFloat = 0.8) async -> Data? {
        guard let image = await captureScreen() else {
            return nil
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            print("⚠️ ScreenshotCapture: Could not convert image to JPEG")
            return nil
        }
        
        print("✅ ScreenshotCapture: Screenshot converted to JPEG")
        print("   - Size: \(jpegData.count) bytes")
        return jpegData
    }
    
    /// Capture screenshot and convert to base64 encoded JPEG string
    /// - Parameter compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: Base64 encoded JPEG string, or nil if capture fails
    func captureScreenAsBase64(compressionQuality: CGFloat = 0.8) async -> String? {
        guard let jpegData = await captureScreenAsJPEG(compressionQuality: compressionQuality) else {
            return nil
        }
        
        let base64String = jpegData.base64EncodedString()
        print("✅ ScreenshotCapture: Screenshot converted to base64")
        print("   - Base64 length: \(base64String.count) characters")
        return base64String
    }
}

// Helper class for stream output
private class CaptureStreamOutput: NSObject, SCStreamOutput {
    private let handler: (CMSampleBuffer, SCStreamOutputType) -> Void
    
    init(handler: @escaping (CMSampleBuffer, SCStreamOutputType) -> Void) {
        self.handler = handler
        super.init()
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        print("📸 CaptureStreamOutput: didOutputSampleBuffer called")
        print("   - Type: \(type)")
        print("   - Sample buffer valid: \(sampleBuffer != nil)")
        if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
            print("   - Format description: \(formatDesc)")
        }
        handler(sampleBuffer, type)
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("❌ CaptureStreamOutput: Stream stopped with error")
        print("   - Error: \(error.localizedDescription)")
    }
}
