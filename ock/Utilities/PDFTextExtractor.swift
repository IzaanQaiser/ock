//
//  PDFTextExtractor.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import PDFKit

/// Fast PDF text extraction using native PDFKit
class PDFTextExtractor {
    static let shared = PDFTextExtractor()
    
    private init() {}
    
    /// Extract all text from a PDF file
    /// - Parameter url: URL to the PDF file
    /// - Returns: Extracted text or nil if extraction fails
    func extractText(from url: URL) -> String? {
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let pdfDocument = PDFDocument(url: url) else {
            print("⚠️ PDFTextExtractor: Could not open PDF at \(url)")
            return nil
        }
        
        var fullText = ""
        let pageCount = pdfDocument.pageCount
        
        print("📄 PDFTextExtractor: Extracting text from \(pageCount) pages...")
        
        for pageIndex in 0..<pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n\n"
            }
        }
        
        let cleanedText = cleanText(fullText)
        print("✅ PDFTextExtractor: Extracted \(cleanedText.count) characters")
        
        return cleanedText.isEmpty ? nil : cleanedText
    }
    
    /// Extract text from any supported document type
    /// - Parameter url: URL to the document
    /// - Returns: Extracted text or nil
    func extractText(fromDocument url: URL) -> String? {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "pdf":
            return extractText(from: url)
        case "txt":
            return extractTextFile(from: url)
        case "rtf":
            return extractRTF(from: url)
        default:
            print("⚠️ PDFTextExtractor: Unsupported file type: \(pathExtension)")
            return nil
        }
    }
    
    /// Extract text from a plain text file
    private func extractTextFile(from url: URL) -> String? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            return cleanText(text)
        } catch {
            print("⚠️ PDFTextExtractor: Could not read text file: \(error)")
            return nil
        }
    }
    
    /// Extract text from RTF file
    private func extractRTF(from url: URL) -> String? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            if let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) {
                return cleanText(attributedString.string)
            }
            return nil
        } catch {
            print("⚠️ PDFTextExtractor: Could not read RTF file: \(error)")
            return nil
        }
    }
    
    /// Clean up extracted text
    private func cleanText(_ text: String) -> String {
        // Remove excessive whitespace and normalize line breaks
        var cleaned = text
        
        // Replace multiple newlines with double newline
        cleaned = cleaned.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Replace multiple spaces with single space
        cleaned = cleaned.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}
