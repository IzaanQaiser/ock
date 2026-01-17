//
//  ContentView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            Group {
                switch appViewModel.appState {
                case .landing:
                    LandingView(
                        onStartSession: {
                            appViewModel.startSession()
                        },
                        onGoToTestEnv: {
                            appViewModel.goToTestEnvironment()
                        }
                    )
                    .transition(.opacity)

                case .testEnvironment:
                    TestEnvironmentView(
                        onBack: {
                            appViewModel.goBack()
                        }
                    )
                    .transition(.opacity)
                    
                case .materials:
                    MaterialsView(
                        onComplete: { materials in
                            appViewModel.completeMaterials(materials)
                        },
                        onBack: {
                            appViewModel.goBack()
                        }
                    )
                    .transition(.opacity)
                    
                case .session:
                    SessionView(
                        materials: appViewModel.materials,
                        onEndSession: {
                            appViewModel.endSession()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: appViewModel.appState)
        }
        .frame(minWidth: 1024, minHeight: 768)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
