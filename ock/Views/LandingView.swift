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
            }
            .padding()

            Spacer()

            VStack(spacing: 12) {
                Text("Test Environment")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.appForeground)
                Text("Use this space to try out APIs and sponsor integrations.")
                    .font(.body)
                    .foregroundColor(.appMutedForeground)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    LandingView(
        onStartSession: {},
        onGoToTestEnv: {}
    )
        .frame(width: 1280, height: 800)
}
