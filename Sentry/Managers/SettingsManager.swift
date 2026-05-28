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
    
    static let shared = SettingsManager()
    
    @AppStorage("showClockWidget") var showClockWidget: Bool = true
    @AppStorage("cliShowTitleBar") var cliShowTitleBar: Bool = true
    @AppStorage("cliLineLimit") var cliLineLimit: Int = 10
    
    private init() {}
}
