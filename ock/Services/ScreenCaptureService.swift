//
//  ScreenCaptureService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import AppKit
import ScreenCaptureKit

@MainActor
class ScreenCaptureService: NSObject {
    static let shared = ScreenCaptureService()
    
    let screenshotsFolder: URL
    private var hasPermission: Bool = false
    
    private override init() {
        // Save screenshots to project root: ock/images/
        let projectFolder = URL(fileURLWithPath: "/Users/izaan/Desktop/programming/ock/images")
        
        // Use project folder (sandbox is disabled)
        screenshotsFolder = projectFolder
        
        super.init()
        
        // Create folder if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: screenshotsFolder, withIntermediateDirectories: true, attributes: nil)
            print("📸 ScreenCaptureService: Screenshots folder: \(screenshotsFolder.path)")
        } catch {
            print("⚠️ ScreenCaptureService: Failed to create screenshots folder: \(error.localizedDescription)")
        }
    }
    
    /// Check and request screen recording permission
    func checkPermission() async -> Bool {
        do {
            // This will trigger the permission prompt if not already granted
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            hasPermission = !content.displays.isEmpty
            print("📸 ScreenCaptureService: Permission check - displays found: \(content.displays.count)")
            return hasPermission
        } catch {
            print("⚠️ ScreenCaptureService: Permission check failed: \(error.localizedDescription)")
            hasPermission = false
            return false
        }
    }
    
    /// Capture a screenshot of the main display and save it
    /// - Returns: The URL of the saved screenshot, or nil if capture failed
    func captureScreen() async -> URL? {
        print("📸 ScreenCaptureService: Capturing screenshot...")
        
        do {
            // Get available content to capture
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // Get the main display
            guard let display = availableContent.displays.first else {
                print("⚠️ ScreenCaptureService: No displays found")
                return nil
            }
            
            print("📸 ScreenCaptureService: Found display: \(display.width)x\(display.height)")
            
            // Create a filter for the display (exclude our own app windows)
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            // Configure the screenshot
            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = true
            
            // Capture the screenshot
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            
            print("📸 ScreenCaptureService: Screenshot captured, saving...")
            
            // Create filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "screenshot_\(timestamp).png"
            let fileURL = screenshotsFolder.appendingPathComponent(filename)
            
            // Convert CGImage to PNG data and save
            let bitmapRep = NSBitmapImageRep(cgImage: image)
            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                print("⚠️ ScreenCaptureService: Failed to convert screenshot to PNG")
                return nil
            }
            
            try pngData.write(to: fileURL)
            print("✅ ScreenCaptureService: Screenshot saved to \(fileURL.path)")
            return fileURL
            
        } catch let error as NSError {
            print("⚠️ ScreenCaptureService: Failed to capture screen: \(error.localizedDescription)")
            print("⚠️ ScreenCaptureService: Error domain: \(error.domain), code: \(error.code)")
            
            // If permission denied, open System Settings
            if error.localizedDescription.contains("declined") || error.code == -3801 {
                print("📸 ScreenCaptureService: Opening Screen Recording settings...")
                openScreenRecordingSettings()
            }
            
            return nil
        }
    }
    
    /// Open Screen Recording settings
    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Get the screenshots folder URL
    func getScreenshotsFolder() -> URL {
        return screenshotsFolder
    }
    
    /// Get all saved screenshots
    func getAllScreenshots() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: screenshotsFolder,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            return files.filter { $0.pathExtension == "png" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            print("⚠️ ScreenCaptureService: Failed to list screenshots: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Delete old screenshots (keep last N)
    func cleanupOldScreenshots(keepLast count: Int = 50) {
        let screenshots = getAllScreenshots()
        guard screenshots.count > count else { return }
        
        let toDelete = screenshots.dropFirst(count)
        for url in toDelete {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ ScreenCaptureService: Deleted old screenshot: \(url.lastPathComponent)")
        }
    }
}
