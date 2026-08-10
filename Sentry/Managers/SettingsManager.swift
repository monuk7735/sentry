//
//  SettingsManager.swift
//  Sentry
//
//  Created by Monu Kumar on 29/05/26.
//

import Foundation
import Combine
import SwiftUI

class SettingsManager: ObservableObject {
    
    enum LockBehavior: String, CaseIterable, Identifiable {
        case custom = "custom"
        case system = "system"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .custom: return "Custom Overlay Lock"
            case .system: return "macOS Lock Screen"
            }
        }
    }
    
    static let shared = SettingsManager()
    
    @AppStorage("lockBehavior") var lockBehavior: LockBehavior = .custom
    @AppStorage("showClockWidget") var showClockWidget: Bool = true
    @AppStorage("cliShowTitleBar") var cliShowTitleBar: Bool = true
    @AppStorage("cliLineLimit") var cliLineLimit: Int = 10
    
    @AppStorage("caffeinePreventSystemSleep") var caffeinePreventSystemSleep: Bool = true
    
    @Published var selectedTab: SettingsTab = .shortcuts
    
    private init() {}
}
