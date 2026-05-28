//
//  CLIManager.swift
//  Sentry
//
//  Created by Monu Kumar on 28/05/26.
//

import Foundation
import Combine

class CLIManager: ObservableObject {
    
    static let shared = CLIManager()
    
    @Published var title: String = ""
    @Published var lines: [String] = []
    @Published var status: String = "" // "running", "success", "failed", "completed", ""
    @Published var isVisible: Bool = false
    @Published var lastUpdated: Date = Date()
    
    private var autoHideTimer: Timer?
    private let notificationName = Notification.Name("com.monuk7735.sentry.cli.update")
    
    private init() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleCliUpdate(_:)),
            name: notificationName,
            object: nil
        )
    }
    
    @objc private func handleCliUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let newTitle = userInfo["title"] as? String ?? "Command Progress"
        let newLines = userInfo["lines"] as? [String] ?? []
        let newStatus = userInfo["status"] as? String ?? ""
        let clearOnExit = userInfo["clearOnExit"] as? Bool ?? false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Invalidate existing timer when a new update starts
            self.autoHideTimer?.invalidate()
            self.autoHideTimer = nil
            
            self.title = newTitle
            self.lines = newLines
            self.status = newStatus
            self.isVisible = !newLines.isEmpty
            self.lastUpdated = Date()
            
            // Handle completion states
            if newStatus == "success" || newStatus == "failed" || newStatus == "completed" {
                if clearOnExit {
                    // Auto-hide after 3 seconds if clearOnExit is set
                    self.autoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                        self?.hide()
                    }
                } else {
                    // Otherwise, auto-hide after 5 minutes of inactivity
                    self.autoHideTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: false) { [weak self] _ in
                        self?.hide()
                    }
                }
            }
        }
    }
    
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.isVisible = false
            self?.status = ""
            self?.lines = []
            self?.title = ""
        }
    }
}
