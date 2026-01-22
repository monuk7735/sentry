//
//  HotKeyManager.swift
//  Sentry
//
//  Created by Monu Kumar on 06/01/26.
//

import Cocoa
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    
    var onLockHotKey: (() -> Void)?
    var onCaffeineHotKey: (() -> Void)?
    
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    
    // IDs
    private let lockHotKeyID = EventHotKeyID(signature: OSType(1196647243), id: 1) // 'SENT', 1
    private let caffeineHotKeyID = EventHotKeyID(signature: OSType(1196647243), id: 2) // 'SENT', 2
    
    private init() {
        registerHotKeys()
        installEventHandler()
    }
    
    deinit {
        unregisterHotKeys()
    }
    
    private func registerHotKeys() {
        // Lock: Cmd + Shift + L (kVK_ANSI_L = 0x25)
        register(keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(cmdKey | shiftKey), id: lockHotKeyID)
        
        // Caffeine: Cmd + Shift + K (kVK_ANSI_K = 0x28)
        register(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(cmdKey | shiftKey), id: caffeineHotKeyID)
    }
    
    private func register(keyCode: UInt32, modifiers: UInt32, id: EventHotKeyID) {
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[id.id] = ref
        } else {
            print("Failed to register hotkey with ID \(id.id): \(status)")
        }
    }
    
    private func unregisterHotKeys() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handler: EventHandlerUPP = { _, event, userData in
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr {
                manager.handleHotKey(id: hotKeyID)
            }
            
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }
    
    private func handleHotKey(id: EventHotKeyID) {
        if id.id == lockHotKeyID.id {
            onLockHotKey?()
        } else if id.id == caffeineHotKeyID.id {
            onCaffeineHotKey?()
        }
    }
}
