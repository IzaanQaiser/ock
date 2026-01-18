//
//  TokenCompanyService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import Combine

/// Service for compressing text using The Token Company's bear-1 model
/// Reduces token usage for LLM inputs while preserving meaning
class TokenCompanyService: ObservableObject {
    static let shared = TokenCompanyService()
    
    private let baseURL = "https://api.thetokencompany.com/v1/compress"
    
    private var apiKey: String {
        get {
            UserDefaults.standard.string(forKey: "tokencompany_api_key") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "tokencompany_api_key")
        }
    }
    
    /// Compression statistics from last operation
    @Published var lastCompressionStats: CompressionStats?
    
    private init() {}
    
    /// Set the Token Company API key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "tokencompany_api_key")
        UserDefaults.standard.synchronize()
        print("🔑 TokenCompanyService: API Key set.")
    }
    
    /// Compress text using bear-1 model
    /// - Parameters:
    ///   - text: The text to compress
    ///   - aggressiveness: How aggressively to compress (0.0-1.0)
    ///     - 0.1-0.3: Light — removes only obvious filler, safe for all use cases
    ///     - 0.4-0.6: Moderate — good balance of compression and quality
    ///     - 0.7-0.9: Aggressive — significant savings, best for cost-sensitive workloads
    /// - Returns: Compressed text and statistics
    func compress(text: String, aggressiveness: Double = 0.5) async throws -> CompressionResult {
        let currentApiKey = apiKey
        guard !currentApiKey.isEmpty else {
            throw TokenCompanyError.apiKeyNotSet
        }
        
        // Skip compression for very short text (not worth the API call)
        if text.count < 50 {
            print("⚡ TokenCompanyService: Text too short (\(text.count) chars), skipping compression")
            return CompressionResult(
                output: text,
                outputTokens: nil,
                originalInputTokens: nil,
                compressionTime: 0,
                wasSkipped: true
            )
        }
        
        guard let url = URL(string: baseURL) else {
            throw TokenCompanyError.invalidURL
        }
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": "bear-1",
            "compression_settings": [
                "aggressiveness": aggressiveness,
                "max_output_tokens": NSNull(),
                "min_output_tokens": NSNull()
            ],
            "input": text
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(currentApiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            throw TokenCompanyError.jsonEncodingFailed(error)
        }
        
        debugLog("🗜️ TokenCompanyService: Compressing text...")
        debugLog("   - Input length: \(text.count) characters")
        debugLog("   - Aggressiveness: \(aggressiveness)")
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let networkTime = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenCompanyError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            print("❌ TokenCompanyService: API error")
            print("   - Status code: \(httpResponse.statusCode)")
            print("   - Response: \(responseBody)")
            throw TokenCompanyError.apiError(statusCode: httpResponse.statusCode, message: responseBody)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let output = json["output"] as? String else {
            print("❌ TokenCompanyService: Could not parse response")
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            print("   - Response: \(responseBody)")
            throw TokenCompanyError.invalidResponseFormat
        }
        
        let outputTokens = json["output_tokens"] as? Int
        let originalInputTokens = json["original_input_tokens"] as? Int
        let compressionTime = json["compression_time"] as? Double ?? networkTime
        
        // Calculate savings
        let tokenSavings: Double?
        if let original = originalInputTokens, let compressed = outputTokens, original > 0 {
            tokenSavings = Double(original - compressed) / Double(original) * 100
        } else {
            tokenSavings = nil
        }
        
        debugLog("✅ TokenCompanyService: Compression complete")
        debugLog("   - Output length: \(output.count) characters")
        if let original = originalInputTokens, let compressed = outputTokens {
            debugLog("   - Tokens: \(original) → \(compressed) (\(String(format: "%.1f", tokenSavings ?? 0))% savings)")
        }
        debugLog("   - Compression time: \(String(format: "%.3f", compressionTime))s")
        
        // Store stats
        let stats = CompressionStats(
            originalTokens: originalInputTokens ?? 0,
            compressedTokens: outputTokens ?? 0,
            savingsPercent: tokenSavings ?? 0,
            compressionTime: compressionTime
        )
        
        await MainActor.run {
            self.lastCompressionStats = stats
        }
        
        return CompressionResult(
            output: output,
            outputTokens: outputTokens,
            originalInputTokens: originalInputTokens,
            compressionTime: compressionTime,
            wasSkipped: false
        )
    }
    
    /// Compress course material context (uses light aggressiveness to preserve meaning)
    /// Best for PDF chunks and lecture notes
    func compressCourseContext(_ text: String) async throws -> String {
        let result = try await compress(text: text, aggressiveness: 0.1)
        return result.output
    }
    
    /// Compress voice transcription (uses minimal aggressiveness)
    /// Best for WhisperFlow transcriptions
    func compressTranscription(_ text: String) async throws -> String {
        let result = try await compress(text: text, aggressiveness: 0.1)
        return result.output
    }
}

// MARK: - Models

struct CompressionResult {
    let output: String
    let outputTokens: Int?
    let originalInputTokens: Int?
    let compressionTime: Double
    let wasSkipped: Bool
}

struct CompressionStats {
    let originalTokens: Int
    let compressedTokens: Int
    let savingsPercent: Double
    let compressionTime: Double
}

// MARK: - Errors

enum TokenCompanyError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case jsonEncodingFailed(Error)
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "Token Company API key not set. Please configure it in settings."
        case .invalidURL:
            return "Invalid Token Company API URL"
        case .jsonEncodingFailed(let error):
            return "Failed to encode JSON for Token Company request: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Token Company API"
        case .invalidResponseFormat:
            return "Could not parse Token Company API response"
        case .apiError(let statusCode, let message):
            return "Token Company API Error \(statusCode): \(message)"
        }
    }
}
