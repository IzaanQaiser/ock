//
//  WindowManager.swift
//  Ock-Cursor
//
//  Created on 2024
//

import AppKit
import SwiftUI

class WindowManager {
    static func minimizeCurrentWindow() {
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSApplication.shared.windows.first {
            window.miniaturize(nil)
        }
    }
    
    static func focusTextField() {
        // Post a notification that can be observed by the text field
        // We'll use a custom approach with NSApp to focus the first responder
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
