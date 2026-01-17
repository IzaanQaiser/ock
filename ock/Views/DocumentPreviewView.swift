//
//  DocumentPreviewView.swift
//  Ock-Cursor
//
//  Created on 2024
//

import SwiftUI
import PDFKit
import AppKit
import QuickLookUI

struct DocumentPreviewView: View {
    let fileURL: URL
    let fileName: String
    
    var body: some View {
        Group {
            if fileURL.pathExtension.lowercased() == "pdf" {
                PDFPreviewView(url: fileURL)
            } else {
                QuickLookPreviewView(url: fileURL)
            }
        }
    }
}

struct PDFPreviewView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        
        // Start accessing security-scoped resource if needed
        let accessing = url.startAccessingSecurityScopedResource()
        context.coordinator.isAccessingSecurityScopedResource = accessing
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document == nil {
            let accessing = url.startAccessingSecurityScopedResource()
            context.coordinator.isAccessingSecurityScopedResource = accessing
            if let document = PDFDocument(url: url) {
                nsView.document = document
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator {
        let url: URL
        var isAccessingSecurityScopedResource: Bool = false
        
        init(url: URL) {
            self.url = url
        }
        
        deinit {
            if isAccessingSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}

struct QuickLookPreviewView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> NSView {
        let coordinator = context.coordinator
        
        let containerView = NSView()
        containerView.wantsLayer = true
        
        // Create a scroll view for the content
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Create content view with file info and preview option
        let contentView = NSView()
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 16
        stackView.edgeInsets = NSEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)
        
        // File icon - access security-scoped resource if needed
        let iconView = NSImageView()
        let accessing = url.startAccessingSecurityScopedResource()
        if FileManager.default.fileExists(atPath: url.path) {
            iconView.image = NSWorkspace.shared.icon(forFile: url.path)
            iconView.image?.size = NSSize(width: 64, height: 64)
        } else {
            iconView.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
            iconView.image?.size = NSSize(width: 64, height: 64)
        }
        if accessing {
            url.stopAccessingSecurityScopedResource()
        }
        iconView.imageScaling = .scaleProportionallyUpOrDown
        
        // File name
        let nameLabel = NSTextField(labelWithString: url.lastPathComponent)
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.maximumNumberOfLines = 2
        nameLabel.lineBreakMode = .byTruncatingMiddle
        
        // Info text
        let infoLabel = NSTextField(wrappingLabelWithString: "This file type can be previewed using Quick Look. Click the button below to open it in the default application.")
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.alignment = .center
        infoLabel.maximumNumberOfLines = 0
        
        // Open button
        let openButton = NSButton(title: "Open in Default App", target: coordinator, action: #selector(Coordinator.openFile))
        openButton.bezelStyle = NSButton.BezelStyle.rounded
        openButton.controlSize = NSControl.ControlSize.regular
        
        // Quick Look button
        let quickLookButton = NSButton(title: "Show Quick Look", target: coordinator, action: #selector(Coordinator.showQuickLook))
        quickLookButton.bezelStyle = NSButton.BezelStyle.rounded
        quickLookButton.controlSize = NSControl.ControlSize.regular
        
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.addArrangedSubview(quickLookButton)
        buttonStack.addArrangedSubview(openButton)
        
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(infoLabel)
        stackView.addArrangedSubview(buttonStack)
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -32),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 32),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -32)
        ])
        
        scrollView.documentView = contentView
        containerView.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject {
        let url: URL
        var isAccessingSecurityScopedResource: Bool = false
        
        init(url: URL) {
            self.url = url
            super.init()
            // Start accessing security-scoped resource if needed
            isAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
        }
        
        deinit {
            if isAccessingSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        @objc func openFile() {
            let accessing = url.startAccessingSecurityScopedResource()
            NSWorkspace.shared.open(url)
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        @objc func showQuickLook() {
            let accessing = url.startAccessingSecurityScopedResource()
            if let panel = QLPreviewPanel.shared() {
                panel.dataSource = self
                panel.reloadData()
                panel.makeKeyAndOrderFront(nil)
            }
            // Keep accessing while Quick Look is open
            // It will be cleaned up in deinit
        }
    }
}

extension QuickLookPreviewView.Coordinator: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return 1
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return QuickLookPreviewItem(url: url)
    }
}

// Wrapper class to make URL work with QLPreviewItem
class QuickLookPreviewItem: NSObject, QLPreviewItem {
    let url: URL
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    var previewItemURL: URL? {
        return url
    }
    
    var previewItemTitle: String? {
        return url.lastPathComponent
    }
}
