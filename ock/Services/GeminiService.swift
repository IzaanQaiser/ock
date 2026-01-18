//
//  GeminiService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import Combine

class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
            private var apiKey: String {
                get {
                    // Always read from UserDefaults - no fallback to prevent caching old keys
                    if let savedKey = UserDefaults.standard.string(forKey: "gemini_api_key"), !savedKey.isEmpty {
                        return savedKey
                    }
                    // Return empty string if not set (will trigger error)
                    return ""
                }
                set {
                    UserDefaults.standard.set(newValue, forKey: "gemini_api_key")
                    UserDefaults.standard.synchronize() // Force immediate write
                }
            }
    
    // Model names to try in order (will be populated from API)
    private var availableModels: [String] = []
    
    private func getBaseURL(for modelName: String) -> String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
    }
    
    private func getModelsListURL() -> String {
        // Always read directly from UserDefaults (no caching)
        let currentApiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        return "https://generativelanguage.googleapis.com/v1beta/models?key=\(currentApiKey)"
    }
    
    /// Fetch available models from Gemini API
    func fetchAvailableModels() async throws -> [String] {
        // Always read directly from UserDefaults (no caching)
        let currentApiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        guard !currentApiKey.isEmpty else {
            throw GeminiError.apiKeyNotSet
        }
        
        guard let url = URL(string: getModelsListURL()) else {
            throw GeminiError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: responseBody)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else {
            throw GeminiError.invalidResponseFormat
        }
        
        // Extract model names that support generateContent
        var modelNames: [String] = []
        for model in models {
            if let name = model["name"] as? String,
               let supportedMethods = model["supportedGenerationMethods"] as? [String],
               supportedMethods.contains("generateContent") {
                // Extract just the model ID (e.g., "gemini-2.0-flash" from "models/gemini-2.0-flash")
                let modelId = name.replacingOccurrences(of: "models/", with: "")
                modelNames.append(modelId)
            }
        }
        
        // Prioritize newer models
        let priorityModels = ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]
        modelNames.sort { model1, model2 in
            let index1 = priorityModels.firstIndex(of: model1) ?? Int.max
            let index2 = priorityModels.firstIndex(of: model2) ?? Int.max
            return index1 < index2
        }
        
        self.availableModels = modelNames
        print("✅ GeminiService: Found \(modelNames.count) available models")
        print("   - Models: \(modelNames.joined(separator: ", "))")
        return modelNames
    }
    
    private init() {
        // Don't set a default key here - let OckCursorApp.init() set it
        // This prevents caching old keys
    }
    
    /// Set the Gemini API key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "gemini_api_key")
        UserDefaults.standard.synchronize() // Force immediate write to disk
        print("🔑 GeminiService: API Key set.")
        print("   - Key preview: \(String(key.prefix(20)))...")
        // Verify it was saved correctly
        let savedKey = UserDefaults.standard.string(forKey: "gemini_api_key")
        if savedKey == key {
            print("   ✅ Key verified in UserDefaults")
        } else {
            print("   ⚠️ Key mismatch! Expected: \(String(key.prefix(20)))..., Got: \(String(savedKey?.prefix(20) ?? "nil"))...")
        }
    }
    
    /// Get the current API key (for debugging)
    func getCurrentAPIKey() -> String {
        // Always read directly from UserDefaults (no caching)
        let currentKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        print("🔑 GeminiService: Current API key from UserDefaults: \(String(currentKey.prefix(20)))...")
        return currentKey
    }
    
    /// Generate content using Gemini API with text and optional image
    /// - Parameters:
    ///   - text: The user's question/prompt
    ///   - imageBase64: Optional base64-encoded image (JPEG/PNG)
    ///   - mimeType: MIME type of the image (default: "image/jpeg")
    /// - Returns: Generated text response
    func generateContent(text: String, imageBase64: String? = nil, mimeType: String = "image/jpeg") async throws -> String {
        // Always read directly from UserDefaults to ensure we get the latest key (no caching)
        let currentApiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        print("🔑 GeminiService: Using API key from UserDefaults: \(String(currentApiKey.prefix(20)))...")
        guard !currentApiKey.isEmpty else {
            print("   ⚠️ API key is empty! Make sure it's set in OckCursorApp.init()")
            throw GeminiError.apiKeyNotSet
        }
        
        // Fetch available models if we haven't already
        if availableModels.isEmpty {
            do {
                _ = try await fetchAvailableModels()
            } catch {
                print("⚠️ GeminiService: Could not fetch models list, using defaults")
                // Fallback to common models
                availableModels = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash", "gemini-1.5-pro"]
            }
        }
        
        // Try each available model until one works
        var lastError: Error?
        // Always read directly from UserDefaults (no caching)
        let apiKeyForRequest = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
        for modelName in availableModels {
            let baseURL = getBaseURL(for: modelName)
            guard let url = URL(string: "\(baseURL)?key=\(apiKeyForRequest)") else {
                continue
            }
            
            do {
                return try await makeRequest(url: url, text: text, imageBase64: imageBase64, mimeType: mimeType, modelName: modelName)
            } catch {
                lastError = error
                // If it's a 404 (model not found), try next model
                if let geminiError = error as? GeminiError,
                   case .apiError(let statusCode, _) = geminiError,
                   statusCode == 404 {
                    print("⚠️ GeminiService: Model '\(modelName)' not available, trying next...")
                    continue
                }
                // For other errors, throw immediately
                throw error
            }
        }
        
        // If all models failed, throw the last error
        throw lastError ?? GeminiError.apiError(statusCode: 404, message: "No available models found")
    }
    
    private func makeRequest(url: URL, text: String, imageBase64: String?, mimeType: String, modelName: String) async throws -> String {
        
        // Build request body according to Gemini API spec
        // System prompt for casual TA behavior - keep responses SHORT
        let systemPrompt = """
You are a chill teaching assistant helping a student. Look at their screen and respond naturally.

RULES:
- Keep it SHORT: 1-2 sentences MAX (under 25 words)
- Be casual and friendly, like a friend helping out
- If they just ask what you see, briefly acknowledge it and offer help
- Only give detailed explanations if they ask a specific question
- No formal language, no bullet points, no lengthy explanations

User says: \(text)
"""
        let promptText = systemPrompt
        
        var parts: [[String: Any]] = [
            ["text": promptText]
        ]
        
        // Add image part if provided (using inlineData, not inline_data)
        if let imageBase64 = imageBase64 {
            parts.append([
                "inlineData": [
                    "mimeType": mimeType,
                    "data": imageBase64
                ]
            ])
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "role": "user",
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "temperature": 0.7
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            throw GeminiError.jsonEncodingFailed(error)
        }
        
        print("🔮 GeminiService: Sending request to Gemini API")
        print("   - Model: \(modelName)")
        print("   - Text length: \(text.count) characters")
        if let imageBase64 = imageBase64 {
            print("   - Image included: \(imageBase64.count) base64 characters")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            print("❌ GeminiService: API error")
            print("   - Model: \(modelName)")
            print("   - Status code: \(httpResponse.statusCode)")
            print("   - Response: \(responseBody)")
            
            // Try to parse error details from response
            var errorMessage = responseBody
            var retryAfter: TimeInterval? = nil
            var quotaLimit: String? = nil
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any] {
                if let message = error["message"] as? String {
                    errorMessage = message
                    print("   - Parsed error message: \(message)")
                    
                    // Extract retry-after time from message (e.g., "Please retry in 48.42572463s")
                    if let retryRange = message.range(of: "Please retry in "),
                       let secondsRange = message.range(of: "s", range: retryRange.upperBound..<message.endIndex) {
                        let secondsString = String(message[retryRange.upperBound..<secondsRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                        if let seconds = Double(secondsString) {
                            retryAfter = seconds
                            print("   - Retry after: \(seconds) seconds")
                        }
                    }
                    
                    // Extract quota limit from message
                    if let limitRange = message.range(of: "limit: `"),
                       let limitEndRange = message.range(of: "`", range: limitRange.upperBound..<message.endIndex) {
                        quotaLimit = String(message[limitRange.upperBound..<limitEndRange.lowerBound])
                        print("   - Quota limit: \(quotaLimit ?? "unknown")")
                    }
                }
                if let status = error["status"] as? String {
                    print("   - Error status: \(status)")
                }
                if let details = error["details"] as? [[String: Any]] {
                    print("   - Error details: \(details)")
                }
            }
            
            // Check for specific error types
            if httpResponse.statusCode == 429 {
                if errorMessage.contains("free_tier") || errorMessage.contains("FreeTier") {
                    let limitText = quotaLimit.map { " (limit: \($0) requests/day)" } ?? ""
                    errorMessage = "Free tier quota exceeded\(limitText). The free tier allows 20 requests per day per model. You can:\n• Wait until tomorrow for the quota to reset\n• Upgrade to a paid plan in Google Cloud Console\n• Use a different API key"
                    if let retrySeconds = retryAfter {
                        errorMessage += "\n\nRetry after: \(Int(retrySeconds)) seconds"
                    }
                } else {
                    errorMessage = "Rate limit exceeded. You may be hitting IP-based rate limits. Try again in a few moments or check your API quota."
                    if let retrySeconds = retryAfter {
                        errorMessage += "\n\nRetry after: \(Int(retrySeconds)) seconds"
                    }
                }
            } else if httpResponse.statusCode == 403 {
                if errorMessage.lowercased().contains("quota") || errorMessage.lowercased().contains("exceeded") {
                    errorMessage = "API quota exceeded. This could be due to:\n- Free tier daily limits\n- IP-based rate limiting\n- Account-level quota limits\n\nCheck your Google Cloud Console for quota details."
                } else {
                    errorMessage = "Permission denied (403). Please check:\n• Your API key is valid\n• The API is enabled in Google Cloud Console\n• Your account has proper permissions"
                }
            }
            
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("❌ GeminiService: Could not parse response")
            let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
            print("   - Response: \(responseBody)")
            throw GeminiError.invalidResponseFormat
        }
        
        print("✅ GeminiService: Received response from Gemini")
        print("   - Model used: \(modelName)")
        print("   - Response length: \(text.count) characters")
        return text
    }
}

enum GeminiError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case jsonEncodingFailed(Error)
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "Gemini API key not set. Please configure it in settings."
        case .invalidURL:
            return "Invalid Gemini API URL"
        case .jsonEncodingFailed(let error):
            return "Failed to encode JSON for Gemini request: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .invalidResponseFormat:
            return "Could not parse Gemini API response"
        case .apiError(let statusCode, let message):
            return "Gemini API Error \(statusCode): \(message)"
        }
    }
}

/// Simple struct for conversation history
struct ConversationMessage {
    let role: String  // "user" or "assistant"
    let content: String
}
