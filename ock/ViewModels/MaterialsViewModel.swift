//
//  MaterialsViewModel.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class MaterialsViewModel: ObservableObject {
    @Published var materials: [UploadedMaterial] = []
    @Published var isDragging: Bool = false
    @Published var isExtracting: Bool = false  // Show loading state during extraction
    
    private let textExtractor = PDFTextExtractor.shared
    
    func addMaterial(from url: URL) {
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .typeIdentifierKey])
        let size = Int64(resourceValues?.fileSize ?? 0)
        let type = resourceValues?.typeIdentifier ?? ""
        
        // Extract text from document (fast, synchronous for PDFs)
        print("📄 MaterialsViewModel: Processing \(url.lastPathComponent)...")
        let extractedText = textExtractor.extractText(fromDocument: url)
        
        if let text = extractedText {
            print("✅ MaterialsViewModel: Extracted \(text.count) chars from \(url.lastPathComponent)")
        } else {
            print("⚠️ MaterialsViewModel: No text extracted from \(url.lastPathComponent)")
        }
        
        let material = UploadedMaterial(
            name: url.lastPathComponent,
            type: type,
            size: size,
            fileURL: url,
            extractedText: extractedText
        )
        
        materials.append(material)
    }
    
    func addMaterials(from urls: [URL], completion: (() -> Void)? = nil) {
        isExtracting = true
        
        // Process on background thread to keep UI responsive
        Task {
            for url in urls {
                // Extract on background
                let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .typeIdentifierKey])
                let size = Int64(resourceValues?.fileSize ?? 0)
                let type = resourceValues?.typeIdentifier ?? ""
                
                debugLog("📄 MaterialsViewModel: Processing \(url.lastPathComponent)...")
                let extractedText = textExtractor.extractText(fromDocument: url)
                
                var originalTokens: Int? = nil
                var compressedTokens: Int? = nil
                
                if let text = extractedText, !text.isEmpty {
                    debugLog("✅ MaterialsViewModel: Extracted \(text.count) chars from \(url.lastPathComponent)")
                    
                    // Compress to get token stats (for display purposes)
                    do {
                        debugLog("🗜️ MaterialsViewModel: Getting compression stats for \(url.lastPathComponent)...")
                        let result = try await TokenCompanyService.shared.compressCourseContext(text)
                        originalTokens = result.originalInputTokens
                        compressedTokens = result.outputTokens
                        if let orig = originalTokens, let comp = compressedTokens {
                            let savings = orig > 0 ? Double(orig - comp) / Double(orig) * 100 : 0
                            debugLog("📊 MaterialsViewModel: \(url.lastPathComponent) - \(orig) → \(comp) tokens (\(String(format: "%.0f", savings))% savings)")
                        }
                    } catch {
                        debugLog("⚠️ MaterialsViewModel: Could not get compression stats: \(error.localizedDescription)")
                    }
                }
                
                let material = UploadedMaterial(
                    name: url.lastPathComponent,
                    type: type,
                    size: size,
                    fileURL: url,
                    extractedText: extractedText,
                    originalTokenCount: originalTokens,
                    compressedTokenCount: compressedTokens
                )
                
                // Update UI on main thread
                await MainActor.run {
                    self.materials.append(material)
                }
            }
            
            await MainActor.run {
                self.isExtracting = false
                completion?()
            }
        }
    }
    
    func removeMaterial(_ id: String) {
        materials.removeAll { $0.id == id }
    }
    
    func clearMaterials() {
        materials = []
    }
    
    func isValidFileType(_ url: URL) -> Bool {
        // Simply check file extension - this is the most reliable method
        let pathExtension = url.pathExtension.lowercased()
        let allowedExtensions = ["pdf", "doc", "docx", "txt", "ppt", "pptx", "rtf"]
        return allowedExtensions.contains(pathExtension)
    }
    
    /// Get total chunks available across all materials
    var totalChunksCount: Int {
        materials.compactMap { $0.textChunks?.count }.reduce(0, +)
    }
    
    /// Check if materials have been processed
    var hasMaterialsWithText: Bool {
        materials.contains { $0.extractedText != nil && !$0.extractedText!.isEmpty }
    }
}
