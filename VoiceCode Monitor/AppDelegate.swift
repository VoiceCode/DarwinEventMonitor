//
//  AppDelegate.swift
//  EventHandler
//
//  Created by Benjamin Meyer on 11/18/15.
//  Copyright © 2015 VoiceCode. All rights reserved.
//

import Cocoa
import PFAssistive
import SwiftyJSON

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var top: PFUIElement?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSWorkspace.sharedWorkspace()
            .notificationCenter.addObserver(self,
                selector: #selector(AppDelegate.applicationActivated(_:)),
                name: NSWorkspaceDidActivateApplicationNotification, object: nil)
        
        NSEvent.addGlobalMonitorForEventsMatchingMask(.LeftMouseDown, handler: self.leftClickHandler)
        NSEvent.addGlobalMonitorForEventsMatchingMask(.LeftMouseUp, handler: self.leftClickUpHandler)
        NSEvent.addGlobalMonitorForEventsMatchingMask(.RightMouseUp, handler: self.rightClickUpHandler)
        NSEvent.addGlobalMonitorForEventsMatchingMask(.KeyUp, handler: self.keyUpHandler)
//        self.startObservingDragon()
        self.observeActivity()
    }
    
    func startObservingDragon() {
        print("checking dragon")
        if self.observeDragonStatusWindow() {
            // cool
        }
        else {
            // try again in 3 seconds
            let delta: Int64 = 3 * Int64(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, delta)
            
            dispatch_after(time, dispatch_get_main_queue(), {
                self.startObservingDragon()
            })
        }

    }
    
    func observeActivity() {
        let delta: Int64 = 5 * Int64(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, delta)
        self.checkActiveElement()
        dispatch_after(time, dispatch_get_main_queue(), {
            self.observeActivity()
        })
    }
    
    func checkActiveElement() {
        print("checkActiveElements")
        if  (self.top == nil)   {
            self.top = PFApplicationUIElement.systemWideUIElementWithDelegate(nil)
        }
        let current = self.top?.AXFocusedApplication
        let window = current?.AXFocusedWindow
        let focused = current?.AXFocusedUIElement
        let windows = current?.AXWindows
        var windowData = [AnyObject]()
        if  (windows != nil) {
            for w in windows! {
                windowData.append(self.windowInfo(w))
            }
        }
        
        let result: JSON = [
            "event": "uiState",
            "currentWindow": self.windowInfo(window),
            "focusedElement": self.elementInfo(focused),
//            "fileName": String(focused?.AXFilename ?? ""),
            "windows": windowData,
//            "AXInsertionPointLineNumber": String(focused?.AXInsertionPointLineNumber ?? ""),
//            "AXWindows": String(focused?.AXWindows ?? ""),
        ]
        print(result)
        
        self.send(result)
    }
    
    func string(item: AnyObject?) -> NSString {
        if item != nil {
            return "\(item!)"
//                .stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
//                .stringByReplacingOccurrencesOfString("\\", withString: "<s_h_a_l_s>")
//                .stringByReplacingOccurrencesOfString("`", withString: "\\`")
        } else {
            return ""
        }
    }
    func size(item: NSSize?) -> AnyObject {
        if item != nil {
            return [item!.width, item!.height]
        } else {
            return []
        }
    }
    func position(item: NSPoint?) -> AnyObject {
        if item != nil {
            return [item!.x, item!.y]
        } else {
            return []
        }
    }
    func range(item: NSRange?) -> AnyObject {
        if item != nil {
            return [item!.location, item!.length]
        } else {
            return []
        }
    }
    func boolean(item: NSNumber?) -> AnyObject {
        if item != nil {
            if (item == 1) {
                return "true"
            } else {
                return "\(item!)"
            }
        } else {
            return []
        }
    }

    func windowInfo(window: PFUIElement?) -> AnyObject {
        if  (window != nil) {
            let windowData: JSON = [
                "title": self.string(window?.AXTitle),
                "identifier": self.string(window?.AXIdentifier),
                "position": self.position(window?.AXPosition?.pointValue),
                "size": self.size(window?.AXSize?.sizeValue),
//                "focused": self.boolean(window?.AXFocused),
//                "fullscreen": self.boolean(window?.AXFullScreen),
//                "minimized": self.boolean(window?.AXMinimized),
//                "attributes": (window?.attributes())!,
            ]
            return windowData.object
        } else {
            return []
        }
    }
    
    func elementInfo(element: PFUIElement?) -> AnyObject {
        if  (element != nil) {
            var value = ""
            let count = element?.AXNumberOfCharacters
            if  (count != nil) {
                if (Int(count!) > 0 && Int(count!) < 10000) {
                    value = self.string(element?.AXValue) as String
                }
            }
            var elementData: JSON = [
                "valueDescription": self.string(element?.AXValueDescription),
//                "value": self.string(element?.AXValue),
                "value": value,
                "selectedText": self.string(element?.AXSelectedText),
                "selectedTextRange": self.range(element?.AXSelectedTextRange?.rangeValue),
                "visibleCharacterRange": self.range(element?.AXVisibleCharacterRange?.rangeValue),
                "insertionPointLineNumber": self.string(element?.AXInsertionPointLineNumber),
                "AXNumberOfCharacters": self.string(element?.AXNumberOfCharacters),
                "position": self.position(element?.AXPosition?.pointValue),
                "size": self.size(element?.AXSize?.sizeValue),
                "role": self.string(element?.AXRole),
                "placeholder": self.string(element?.AXPlaceholderValue),
//                "attributes": (element?.attributes())!,
            ]
            return elementData.object
        } else {
            return []
        }
    }
    
    func observeDragonStatusWindow() -> DarwinBoolean {
        if self.applicationIsRunning("com.dragon.dictate") {
            let rt = self.findRecognizedTextElement()
            if (rt != nil) {
                let observer = PFObserver(bundleIdentifier: "com.dragon.dictate", notificationDelegate: self, callbackSelector: #selector(AppDelegate.recognizedTextChanged(_:notification:element:contextInfo:)))
                observer!.registerForNotification(kAXValueChangedNotification, fromElement: rt, contextInfo: nil)
                return true
            }
        }
        return false
    }

    func recognizedTextChanged(observer: PFObserver, notification: String, element: PFUIElement!, contextInfo: AnyObject) {
        var phrase = ""
        
        if (element.existsValueForAttribute("AXValue")) {
            phrase = (element.AXValue as? String)!
        }
        else {
            phrase = ""
        }
        
        let result = [
            "event": "recognizedText",
            "phrase": phrase
        ]
        
        self.sendToVoiceCode(self.toJson(result))
    }
    func findRecognizedTextElement() -> PFUIElement? {
        let window = self.findDragonStatusWindow()
        if (window != nil) {
            for child in window!.AXChildren! {
                if (child.existsValueForAttribute("AXDescription")) {
                    if (child.AXDescription == "Recognized Commands") {
                        return child
                    }
                }
            }
        }
        return nil
    }
    
    func findDragonStatusWindow() -> PFUIElement? {
        let dragon: PFApplicationUIElement = PFApplicationUIElement(bundleIdentifier: "com.dragon.dictate", delegate: nil)!
        if (dragon.existsValueForAttribute("AXChildren")) {
            for child in dragon.AXChildren! {
                if (child.existsValueForAttribute("AXTitle")) {
                    if (child.AXTitle == "Dictate Status Window") {
                        return child
                    }
                }
            }
        }
        return nil
    }
    
    func applicationIsRunning(bundleIdentifier: NSString) -> DarwinBoolean {
        for app in NSWorkspace.sharedWorkspace().runningApplications {
            if (app.bundleIdentifier == bundleIdentifier) {
                return true
            }
        }
        return false
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationActivated(notification: NSNotification!) {
        let application = notification.object?.frontmostApplication
        let result = [
            "event": "applicationChanged",
            "bundleId": application!!.bundleIdentifier ?? "",
            "name": application!!.localizedName ?? ""
        ]
        
        self.sendToVoiceCode(self.toJson(result))
        // self.checkActiveElement()
    }
    
    func leftClickHandler(event: NSEvent) {
        let location = NSEvent.mouseLocation()
        let result = [
            "event": "leftClick",
            "x": location.x,
            "y": location.y,
            "windowRelativeX": event.locationInWindow.x,
            "windowRelativeY": event.locationInWindow.y,
            "windowNumber": event.windowNumber,
            "clickCount": event.clickCount
        ]
        self.sendToVoiceCode(self.toJson(result))
        // self.checkActiveElement()
    }
    func leftClickUpHandler(event: NSEvent) {
        // self.checkActiveElement()
    }
    func rightClickUpHandler(event: NSEvent) {
        // self.checkActiveElement()
    }
    func keyUpHandler(event: NSEvent) {
        print(event)
        var flags = [String]()
        if (event.modifierFlags.contains(.Command)) {
            flags += ["command"]
        }
        if (event.modifierFlags.contains(.Control)) {
            flags += ["control"]
        }
        if (event.modifierFlags.contains(.Shift)) {
            flags += ["shift"]
        }
        if (event.modifierFlags.contains(.Option)) {
            flags += ["option"]
        }
        let result = [
            "event": "keyUp",
            "windowNumber": event.windowNumber,
            "keyCode": String(event.keyCode),
            "flags": flags,
//            "characters": String(event.characters ?? ""),
//            "charactersIgnoringModifiers": String(event.charactersIgnoringModifiers ?? ""),
            "x": event.locationInWindow.x,
            "y": event.locationInWindow.y,
            "type": String(event.type),
            "timestamp": event.timestamp
        ]
        print(result)
        self.sendToVoiceCode(self.toJson(result))
//        self.checkActiveElement()
    }
    
    func toJson(object: NSObject) -> NSString {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            return jsonString
        } catch let error as NSError {
            print(error)
            return ""
        }
    }
    
    func send(item: JSON) {
        let jsonString = item.rawString()
        print("-----------------------------------\n\n")
        print(item)
//        let normalized = jsonString!.stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
        self.sendToVoiceCode(jsonString!)
    }
    
    func sendToVoiceCode(payload: NSString) {
//        print(payload)
//        print("echo '\(payload)' | nc -U /tmp/voicecode_events.sock")
//        self.exec("echo \"\(payload)' | nc -U /tmp/voicecode_events.sock")
//        self.exec("echo \"\(payload)' | nc -U /tmp/voicecode_events_dev.sock")
        self.nc(payload as String, path: "/tmp/voicecode_events.sock")
        self.nc(payload as String, path: "/tmp/voicecode_events_dev.sock")
//        let stdout = NSFileHandle.fileHandleWithStandardOutput()
//        if let data = payload.dataUsingEncoding(NSUTF8StringEncoding) {
//            stdout.writeData(data)
//        }
    }
    
    func nc(command: String, path: String) {
        let task = NSTask()
        task.launchPath = "/usr/bin/nc"
        task.arguments = ["-U", path]
        let inputPipe = NSPipe()
        let handle = inputPipe.fileHandleForWriting
        task.standardInput = inputPipe
        task.launch()
        handle.writeData(command.dataUsingEncoding(NSUTF8StringEncoding)!)
        handle.closeFile()
    }
    
    func exec(cmdname: String) -> NSString {
        var result = ""
        let task = NSTask()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", cmdname]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: NSUTF8StringEncoding) {
            print(output)
            result = output as String
        }
        
        task.waitUntilExit()
//        let status = task.terminationStatus
//        print(status)
        
        return result
    }
    
//    func watchDragon() {
//        let dragon = NSRunningApplication.runningApplicationsWithBundleIdentifier("com.dragon.dictate")
//        print(dragon)
//    }
    
}
