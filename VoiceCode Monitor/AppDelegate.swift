//
//  AppDelegate.swift
//  EventHandler
//
//  Created by Benjamin Meyer on 11/18/15.
//  Copyright © 2015 VoiceCode. All rights reserved.
//

import Cocoa
import PFAssistive

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSWorkspace.sharedWorkspace()
            .notificationCenter.addObserver(self,
                selector: "applicationActivated:",
                name: NSWorkspaceDidActivateApplicationNotification, object: nil)
        
        NSEvent.addGlobalMonitorForEventsMatchingMask(.LeftMouseDownMask, handler: self.leftClickHandler)
        self.startObservingDragon()
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
    
    func observeDragonStatusWindow() -> DarwinBoolean {
        if self.applicationIsRunning("com.dragon.dictate") {
            let rt = self.findRecognizedTextElement()
            if (rt != nil) {
                let observer = PFObserver(bundleIdentifier: "com.dragon.dictate", notificationDelegate: self, callbackSelector: Selector("recognizedTextChanged:notification:element:contextInfo:"))
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

    }
    
    func leftClickHandler(event: NSEvent) {
        let location = NSEvent.mouseLocation()
        let result = [
            "event": "leftClick",
            "x": location.x,
            "y": location.y,
            "windowRelativeX": event.locationInWindow.x,
            "windowRelativeY": event.locationInWindow.y,
            "windowNumber": event.windowNumber
        ]
        self.sendToVoiceCode(self.toJson(result))
    }
    
    func toJson(object: NSObject) -> NSString {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            let normalized = jsonString.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
            return normalized
        } catch let error as NSError {
            print(error)
            return ""
        }
    }
    
    func sendToVoiceCode(payload: NSString) {
        print(payload)
        self.exec("echo \"\(payload)\" | nc -U /tmp/voicecode_events.sock")
        self.exec("echo \"\(payload)\" | nc -U /tmp/voicecode_events_dev.sock")
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