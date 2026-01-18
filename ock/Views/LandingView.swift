//
//  LandingView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct LandingView: View {
    let onStartSession: () -> Void
    let onGoToTestEnv: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Subtle background glow
            Circle()
                .fill(Color.white.opacity(0.02))
                .frame(width: 600, height: 600)
                .blur(radius: 100)
                .offset(x: 0, y: 0)
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Logo
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text("ock")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)
                                )
                        }
                        Spacer()
                    }
                    .padding(.bottom, 32)
                    
                    // Tagline
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.appMutedForeground)
                        Text("Your personal teaching assistant")
                            .font(.caption)
                            .foregroundColor(.appMutedForeground)
                    }
                    .padding(.bottom, 24)
                    
                    // Main headline
                    Text("Study smarter, not harder")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.appForeground)
                        .multilineTextAlignment(.center)
                        .tracking(-0.5)
                        .padding(.bottom, 24)
                    
                    // Subheading
                    Text("Like having a TA beside you 24/7. ock sees your screen, understands your materials, and explains concepts in your own course language.")
                        .font(.body)
                        .foregroundColor(.appMutedForeground)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 512)
                        .padding(.bottom, 48)
                    
                    // CTA Buttons
                    HStack(spacing: 12) {
                        Button(action: onStartSession) {
                            HStack(spacing: 8) {
                                Text("Start a session")
                                    .font(.body.weight(.medium))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 20))
                                    .offset(x: isHovering ? 2 : 0)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isHovering = hovering
                            }
                        }
                        .opacity(isHovering ? 0.9 : 1.0)

                        Button(action: onGoToTestEnv) {
                            HStack(spacing: 8) {
                                Text("Go to Test Env")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.appForeground)
                            .padding(.horizontal, 24)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appMutedForeground, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Features hint
                    HStack(spacing: 32) {
                        FeatureHint(text: "Screen sharing")
                        FeatureHint(text: "Voice conversation")
                        FeatureHint(text: "Course-aware")
                    }
                    .padding(.top, 64)
                }
                .frame(maxWidth: 672)
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
    }
}

struct FeatureHint: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.appSuccess)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption)
                .foregroundColor(.appMutedForeground)
        }
    }
}

struct TestEnvironmentView: View {
    let onBack: () -> Void
    
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var lastResponse: String = ""
    @State private var messageCount: Int = 0

    enum ConnectionStatus {
        case unknown, checking, connected, disconnected
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .checking: return .yellow
            case .connected: return .green
            case .disconnected: return .red
            }
        }
        
        var text: String {
            switch self {
            case .unknown: return "Not checked"
            case .checking: return "Checking..."
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                        Text("Back")
                            .font(.caption)
                    }
                    .foregroundColor(.appMutedForeground)
                }
                .buttonStyle(.plain)

                Spacer()
                
                // Connection status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionStatus.color)
                        .frame(width: 8, height: 8)
                    Text(connectionStatus.text)
                        .font(.caption)
                        .foregroundColor(.appMutedForeground)
                }
            }
            .padding()

            Spacer()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Test Environment")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.appForeground)
                    Text("Use this space to try out APIs and sponsor integrations.")
                        .font(.body)
                        .foregroundColor(.appMutedForeground)
                }
                
                // Backend test section
                VStack(spacing: 16) {
                    Text("Backend Connection Test")
                        .font(.headline)
                        .foregroundColor(.appForeground)
                    
                    Text("Make sure the backend is running:\ncd backend && npm install && npm start")
                        .font(.caption)
                        .foregroundColor(.appMutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        // Health check button
                        Button(action: checkHealth) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                Text("Check Health")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        // Send message button
                        Button(action: sendTestMessage) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                Text("Send Test Message")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.appForeground)
                            .padding(.horizontal, 20)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.appMutedForeground, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Response display
                    if !lastResponse.isEmpty {
                        VStack(spacing: 8) {
                            Text("Last Response:")
                                .font(.caption)
                                .foregroundColor(.appMutedForeground)
                            Text(lastResponse)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.appForeground)
                                .padding(12)
                                .frame(maxWidth: 400)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appSecondary)
                                )
                        }
                    }
                    
                    if messageCount > 0 {
                        Text("Messages sent: \(messageCount)")
                            .font(.caption)
                            .foregroundColor(.appMutedForeground)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                )
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private func checkHealth() {
        connectionStatus = .checking
        lastResponse = ""
        
        Task {
            do {
                let isHealthy = try await BackendService.shared.healthCheck()
                await MainActor.run {
                    connectionStatus = isHealthy ? .connected : .disconnected
                    lastResponse = isHealthy ? "✅ Backend is healthy!" : "❌ Backend returned unhealthy status"
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .disconnected
                    lastResponse = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func sendTestMessage() {
        let message = "Hello from ock app! Test message #\(messageCount + 1)"
        
        Task {
            do {
                let success = try await BackendService.shared.sendLogMessage(message, source: "TestEnvironment")
                await MainActor.run {
                    if success {
                        messageCount += 1
                        lastResponse = "✅ Message sent successfully!\nCheck your backend logs."
                        connectionStatus = .connected
                    } else {
                        lastResponse = "❌ Message send failed"
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .disconnected
                    lastResponse = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    LandingView(
        onStartSession: {},
        onGoToTestEnv: {}
    )
        .frame(width: 1280, height: 800)
}
