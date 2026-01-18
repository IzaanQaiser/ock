//
//  MaterialsContextService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

/// Fast keyword-based context retrieval from course materials
/// No external dependencies - uses simple TF-IDF-like scoring for speed
class MaterialsContextService {
    static let shared = MaterialsContextService()
    
    private init() {}
    
    /// Maximum characters to include in context (keeps responses fast)
    private let maxContextLength = 3000
    
    /// Get relevant context from materials based on the user's question
    /// - Parameters:
    ///   - query: The user's question
    ///   - materials: Array of uploaded materials with extracted text
    /// - Returns: Relevant context string to include in the prompt
    func getRelevantContext(for query: String, from materials: [UploadedMaterial]) -> String {
        let startTime = Date()
        
        // Extract keywords from query
        let queryKeywords = extractKeywords(from: query)
        
        guard !queryKeywords.isEmpty else {
            print("⚠️ MaterialsContextService: No keywords extracted from query")
            return ""
        }
        
        print("🔍 MaterialsContextService: Searching for keywords: \(queryKeywords.joined(separator: ", "))")
        
        // Score and rank all chunks
        var scoredChunks: [(chunk: String, score: Double, source: String)] = []
        
        for material in materials {
            guard let chunks = material.textChunks, !chunks.isEmpty else { continue }
            
            for chunk in chunks {
                let score = scoreChunk(chunk, keywords: queryKeywords)
                if score > 0 {
                    scoredChunks.append((chunk, score, material.name))
                }
            }
        }
        
        // Sort by score (highest first)
        scoredChunks.sort { $0.score > $1.score }
        
        // Take top chunks that fit within context limit
        var context = ""
        var usedSources: Set<String> = []
        
        for (chunk, score, source) in scoredChunks {
            let chunkWithSource = "[\(source)]: \(chunk)\n\n"
            
            if context.count + chunkWithSource.count <= maxContextLength {
                context += chunkWithSource
                usedSources.insert(source)
            } else if context.count >= maxContextLength / 2 {
                // We have enough context
                break
            }
        }
        
        let elapsed = Date().timeIntervalSince(startTime) * 1000
        print("✅ MaterialsContextService: Found \(scoredChunks.count) relevant chunks in \(String(format: "%.1f", elapsed))ms")
        print("   - Using context from: \(usedSources.joined(separator: ", "))")
        print("   - Context length: \(context.count) chars")
        
        return context
    }
    
    /// Extract meaningful keywords from a query
    private func extractKeywords(from text: String) -> [String] {
        // Common stop words to filter out
        let stopWords: Set<String> = [
            "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "must", "shall", "can", "need", "dare",
            "ought", "used", "to", "of", "in", "for", "on", "with", "at", "by",
            "from", "as", "into", "through", "during", "before", "after", "above",
            "below", "between", "under", "again", "further", "then", "once",
            "here", "there", "when", "where", "why", "how", "all", "each",
            "few", "more", "most", "other", "some", "such", "no", "nor", "not",
            "only", "own", "same", "so", "than", "too", "very", "just", "also",
            "now", "and", "but", "or", "if", "because", "until", "while",
            "this", "that", "these", "those", "what", "which", "who", "whom",
            "i", "me", "my", "myself", "we", "our", "you", "your", "he", "him",
            "his", "she", "her", "it", "its", "they", "them", "their",
            "explain", "tell", "show", "help", "understand", "mean", "means",
            "please", "thanks", "okay", "right", "here", "one"
        ]
        
        // Tokenize and filter
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { word in
                word.count >= 2 &&
                !stopWords.contains(word) &&
                !word.allSatisfy { $0.isNumber }
            }
        
        // Return unique keywords
        return Array(Set(words))
    }
    
    /// Score a chunk based on keyword matches
    private func scoreChunk(_ chunk: String, keywords: [String]) -> Double {
        let chunkLower = chunk.lowercased()
        var score: Double = 0
        
        for keyword in keywords {
            // Count occurrences of each keyword
            var searchRange = chunkLower.startIndex..<chunkLower.endIndex
            var count = 0
            
            while let range = chunkLower.range(of: keyword, options: .literal, range: searchRange) {
                count += 1
                searchRange = range.upperBound..<chunkLower.endIndex
            }
            
            if count > 0 {
                // TF-like scoring: diminishing returns for multiple occurrences
                score += 1.0 + log(Double(count))
                
                // Bonus for longer keywords (more specific)
                if keyword.count >= 5 {
                    score += 0.5
                }
                if keyword.count >= 8 {
                    score += 0.5
                }
            }
        }
        
        // Normalize by chunk length (prefer denser matches)
        let lengthFactor = Double(chunk.count) / 500.0
        if lengthFactor > 0 {
            score = score / sqrt(lengthFactor)
        }
        
        return score
    }
    
    /// Build a summary of all available materials (for system context)
    func getMaterialsSummary(from materials: [UploadedMaterial]) -> String {
        guard !materials.isEmpty else { return "" }
        
        var summary = "Available course materials:\n"
        for material in materials {
            let hasText = material.extractedText != nil && !material.extractedText!.isEmpty
            let textStatus = hasText ? "(\(material.textChunks?.count ?? 0) chunks)" : "(no text extracted)"
            summary += "- \(material.name) \(textStatus)\n"
        }
        
        return summary
    }
}
