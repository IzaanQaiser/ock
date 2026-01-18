//
//  AppState.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation

enum AppState: Equatable {
    case landing
    case testEnvironment
    case projectsHub
    case materials
    case session(projectId: String)
}
