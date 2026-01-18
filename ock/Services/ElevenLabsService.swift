//
//  ElevenLabsService.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import AVFoundation
import AppKit
import Combine

class ElevenLabsService: NSObject, ObservableObject {
    static let shared = ElevenLabsService()
    
    // API Configuration
            private var apiKey: String {
                get {
                    UserDefaults.standard.string(forKey: "elevenlabs_api_key") ?? "YOUR_ELEVENLABS_API_KEY_HERE"
                }
                set {
                    UserDefaults.standard.set(newValue, forKey: "elevenlabs_api_key")
                }
            }
    private let baseURL = "https://api.elevenlabs.io/v1"
    private let defaultVoiceId = "21m00Tcm4TlvDq8ikWAM" // Default voice (Rachel)
    private let defaultModelId = "eleven_multilingual_v2" // Eleven Multilingual v2
    
    // Audio playback
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentPlayingMessageId: String? = nil
    
    private override init() {
        super.init()
        // Initialize with placeholder API key if not set (user should set their own key)
        if UserDefaults.standard.string(forKey: "elevenlabs_api_key") == nil {
            UserDefaults.standard.set("YOUR_ELEVENLABS_API_KEY_HERE", forKey: "elevenlabs_api_key")
            print("⚠️ ElevenLabsService: Using placeholder API key. Please set your ElevenLabs API key.")
        }
    }
    
    /// Set the ElevenLabs API key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "elevenlabs_api_key")
    }
    
            /// Convert text to speech and play it
            /// - Parameters:
            ///   - text: The text to convert to speech
            ///   - messageId: Optional message ID to track which message is playing
            ///   - voiceId: Optional voice ID (defaults to Rachel)
            ///   - modelId: Optional model ID (defaults to eleven_multilingual_v2)
            func speak(text: String, messageId: String? = nil, voiceId: String? = nil, modelId: String? = nil) async throws {
                let currentApiKey = apiKey
                guard !currentApiKey.isEmpty else {
                    throw ElevenLabsError.apiKeyNotSet
                }

                // Stop any currently playing audio
                stop()

                print("🔊 ElevenLabsService: Starting TTS generation")
                let generationStartTime = Date()
                
                // Generate audio from text (this is the slow part - API call)
                let audioData = try await generateSpeech(
                    text: text,
                    voiceId: voiceId ?? defaultVoiceId,
                    modelId: modelId ?? defaultModelId,
                    apiKey: currentApiKey
                )
                
                let generationTime = Date().timeIntervalSince(generationStartTime)
                print("⏱️ ElevenLabsService: TTS generation took \(String(format: "%.2f", generationTime)) seconds")

                // Play the audio (this is fast - just playback)
                try await playAudio(data: audioData, messageId: messageId)
            }
    
    /// Generate speech from text using ElevenLabs API
    private func generateSpeech(text: String, voiceId: String, modelId: String, apiKey: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)") else {
            throw ElevenLabsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        // Request body
        let requestBody: [String: Any] = [
            "text": text,
            "model_id": modelId,
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorMessage = errorData["detail"] as? String {
                    throw ElevenLabsError.apiError(message: errorMessage)
                } else if let errorMessage = errorData["detail"] as? [String: Any] {
                    throw ElevenLabsError.apiError(message: String(describing: errorMessage))
                }
            }
            throw ElevenLabsError.apiError(message: "HTTP \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    /// Play audio data
    private func playAudio(data: Data, messageId: String?) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.prepareToPlay()
                    
                    // Play audio
                    if self?.audioPlayer?.play() == true {
                        self?.isPlaying = true
                        self?.currentPlayingMessageId = messageId
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: ElevenLabsError.playbackFailed)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Stop current playback
    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.audioPlayer?.stop()
            self?.audioPlayer = nil
            self?.isPlaying = false
            self?.currentPlayingMessageId = nil
        }
    }
    
    /// Pause current playback
    func pause() {
        DispatchQueue.main.async { [weak self] in
            self?.audioPlayer?.pause()
            self?.isPlaying = false
        }
    }
    
    /// Resume paused playback
    func resume() {
        DispatchQueue.main.async { [weak self] in
            if self?.audioPlayer?.play() == true {
                self?.isPlaying = true
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension ElevenLabsService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.currentPlayingMessageId = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.currentPlayingMessageId = nil
            print("⚠️ ElevenLabsService: Audio playback error: \(error?.localizedDescription ?? "Unknown")")
        }
    }
}

// MARK: - Errors
enum ElevenLabsError: LocalizedError {
    case apiKeyNotSet
    case invalidURL
    case invalidResponse
    case apiError(message: String)
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotSet:
            return "ElevenLabs API key not set. Please configure it in settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from ElevenLabs API"
        case .apiError(let message):
            return "ElevenLabs API error: \(message)"
        case .playbackFailed:
            return "Failed to play audio"
        }
    }
}
