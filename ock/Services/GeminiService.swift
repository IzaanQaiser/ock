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
            UserDefaults.standard.string(forKey: "gemini_api_key") ?? "AIzaSyCPY7RGCCIcIk2kOAZKJPvLtmC7TpgWpuU"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "gemini_api_key")
        }
    }
    
    // Model names to try in order (will be populated from API)
    private var availableModels: [String] = []
    
    private func getBaseURL(for modelName: String) -> String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
    }
    
    private func getModelsListURL() -> String {
        let currentApiKey = apiKey
        return "https://generativelanguage.googleapis.com/v1beta/models?key=\(currentApiKey)"
    }
    
    /// Fetch available models from Gemini API
    func fetchAvailableModels() async throws -> [String] {
        let currentApiKey = apiKey
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
        // Initialize with default API key if not set
        if UserDefaults.standard.string(forKey: "gemini_api_key") == nil {
            UserDefaults.standard.set("AIzaSyCPY7RGCCIcIk2kOAZKJPvLtmC7TpgWpuU", forKey: "gemini_api_key")
            print("✅ GeminiService: Default API key initialized")
        }
    }
    
    /// Set the Gemini API key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "gemini_api_key")
        print("🔑 GeminiService: API Key set.")
    }
    
    /// Generate content using Gemini API with text and optional image
    /// - Parameters:
    ///   - text: The user's question/prompt
    ///   - imageBase64: Optional base64-encoded image (JPEG/PNG)
    ///   - mimeType: MIME type of the image (default: "image/jpeg")
    /// - Returns: Generated text response
    func generateContent(text: String, imageBase64: String? = nil, mimeType: String = "image/jpeg") async throws -> String {
        let currentApiKey = apiKey
        guard !currentApiKey.isEmpty else {
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
        for modelName in availableModels {
            let baseURL = getBaseURL(for: modelName)
            guard let url = URL(string: "\(baseURL)?key=\(currentApiKey)") else {
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
        // Add instruction to keep responses concise
        let promptText = "Keep your response brief and simple (under 150 words). Be direct and concise.\n\n\(text)"
        
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
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: responseBody)
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
