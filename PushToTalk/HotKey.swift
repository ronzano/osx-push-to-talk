//
//  HotKey.swift
//  PushToTalk
//
//  Created by Jeremy Ellison on 5/14/20.
//  Copyright © 2020 yulrizka. All rights reserved.
//

import AppKit
import Foundation

class HotKey {
    var enabled = true
    let microphone: Microphone
    let menuItem: NSMenuItem
    var keyCode: UInt16 = 61
    var modifierFlags = NSEvent.ModifierFlags.option
    var recordingHotKey = false
    var previousTime = NSDate().timeIntervalSince1970

    init(microphone: Microphone, menuItem: NSMenuItem) {
        UserDefaults.standard.register(defaults: ["keyCode": 61, "modifierFlags": NSEvent.ModifierFlags.option.rawValue])
        keyCode = UInt16(UserDefaults.standard.integer(forKey: "keyCode"))
        modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(UserDefaults.standard.integer(forKey: "modifierFlags")))
        self.menuItem = menuItem
        self.menuItem.title = "Change HotKey (\(keyCode))"

        self.microphone = microphone
        // handle when application is on background
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.flagsChanged, handler: handleFlagChangedEvent)

        // handle when application is on foreground
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.flagsChanged, handler: { (theEvent) -> NSEvent? in
            self.handleFlagChangedEvent(theEvent)
            return theEvent
        })
    }

    func toggle() {
        if enabled == true {
            microphone.status = MicrophoneStatus.Speaking
            enabled = false
        } else {
            microphone.status = MicrophoneStatus.Muted
            enabled = true
        }
    }

    func recordNewHotKey() {
        recordingHotKey = true
    }

    internal func handleFlagChangedEvent(_ theEvent: NSEvent!) {
        if recordingHotKey {
            recordingHotKey = false
            keyCode = theEvent.keyCode
            modifierFlags = theEvent.modifierFlags
            menuItem.title = "Change HotKey (\(keyCode))"
            UserDefaults.standard.set(keyCode, forKey: "keyCode")
            UserDefaults.standard.set(modifierFlags.rawValue, forKey: "modifierFlags")
            return
        }
        guard theEvent.keyCode == keyCode else { return }
        // guard enabled else { return }
        if (enabled) {
            microphone.status = theEvent.modifierFlags.contains(modifierFlags) ? .Speaking : .Muted
        }
        let timeInterval = NSDate().timeIntervalSince1970
        let timediff = timeInterval - previousTime
        if (NSEvent.modifierFlags.rawValue > 0 && timediff < 0.1) {
            previousTime = 0
            self.toggle()
        } else {
            previousTime = timeInterval
        }
    }
}
