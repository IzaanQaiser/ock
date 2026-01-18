//
//  BackendService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

/// Simple service to communicate with the Node.js backend
class BackendService {
    static let shared = BackendService()
    
    private let baseURL = "http://localhost:3001"
    
    private init() {}
    
    /// Send a log message to the backend
    func sendLogMessage(_ message: String, source: String = "ock-app") async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/api/log") else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "message": message,
            "source": source
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BackendError.requestFailed
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let success = json["success"] as? Bool {
            return success
        }
        
        return false
    }
    
    /// Check if the backend is running
    func healthCheck() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw BackendError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? String {
            return status == "ok"
        }
        
        return false
    }
}

enum BackendError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}
