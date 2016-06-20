//
//  AppDelegate.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 13/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
	@IBAction func openDocument(sender: AnyObject) {
		let op = NSOpenPanel()
		op.allowsMultipleSelection = false
		if (op.runModal() == NSModalResponseOK) {
			let url = op.URL!
			let array = NSArray(contentsOfURL: url)!
			
			var items = [WikiLanguageArticles]()
			
			for item in array {
				items.append(WikiLanguageArticles(from: item as! [String: AnyObject])!)
			}
			DataManager.sharedManager.resetLBA(Set(items))

		}
		
	}

	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
	}

	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}
	
	func application(sender: NSApplication, openFile filename: String) -> Bool {
		print(filename)
		return true
	}
}

