//
//  FileLogger.swift
//  Ock-Cursor
//
//  Created on 2024
//

import Foundation
import os.log

/// Logger using Apple's os_log system
/// View in Console.app: filter by "ock" or process name
/// Or run in terminal: log stream --predicate 'subsystem == "com.ock.debug"' --level debug
class FileLogger {
    static let shared = FileLogger()
    
    private let logger = Logger(subsystem: "com.ock.debug", category: "general")
    
    private init() {
        // Log startup
        logger.notice("🚀 OCK Debug Logger initialized")
        print("📝 FileLogger: Use Console.app or run: log stream --predicate 'subsystem == \"com.ock.debug\"' --level debug")
    }
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        
        // Log to Apple's unified logging (Console.app)
        logger.notice("[\(fileName):\(line)] \(message)")
        
        // Also print to Xcode console
        print("🔷 \(message)")
    }
}

// Global convenience function
func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    FileLogger.shared.log(message, file: file, function: function, line: line)
}
