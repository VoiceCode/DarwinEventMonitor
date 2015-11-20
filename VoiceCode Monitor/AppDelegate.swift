//
//  AppDelegate.swift
//  EventHandler
//
//  Created by Benjamin Meyer on 11/18/15.
//  Copyright © 2015 VoiceCode. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        NSWorkspace.sharedWorkspace()
            .notificationCenter.addObserver(self,
                selector: "applicationActivated:",
                name: NSWorkspaceDidActivateApplicationNotification, object: nil)
        
        NSEvent.addGlobalMonitorForEventsMatchingMask(.LeftMouseDownMask, handler: self.leftClickHandler)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationActivated(notification: NSNotification!) {
        print(notification.object?.frontmostApplication!!.localizedName)
    }
    
    func leftClickHandler(event: NSEvent) {
        print(event)
        self.sendToVoiceCode("somethin")
    }
    
    func sendToVoiceCode(payload: NSString) {
        self.exec("echo \"hello\" | nc -U /tmp/voicecode_events.sock")
    }
    
    func exec(cmdname: String) -> NSString
    {
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
        let status = task.terminationStatus
        
        print(status)
        
        return result
    }
    
}