//
//  DataManager.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 15/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

protocol DataManagerDelegate: class {
	func reportProgress(sender: DataManager, progress: Int, total: Int)
	func reportCompletion(sender: DataManager)
}

class DataManager {
	
	init() {
		
	}
	
	static let sharedManager = DataManager()
	static let DataManagerReportCompletionNotificationName = "DataManagerReportCompletion"
	
	weak var delegate: DataManagerDelegate?
		
	private func work(text: String) {
		let start = NSDate()
		
		let queue = NSOperationQueue()
		queue.qualityOfService = .Background
		queue.maxConcurrentOperationCount = 50
		
		count = 0
		
		var urls = Set<String>()
		text.enumerateLines { (line, stop) in
			urls.insert(line)
		}
		
		var coordinates_count = 0
		for line in urls {
			
			
			
			let op = NSBlockOperation(block: {
				guard let article = WikiArticle(string: line)	else { return }
				guard !self.articles.contains(article)			else { return }
				
				article.populateFields()
				
				if article.coordinates != nil { coordinates_count += 1 }
				self.articles.insert(article)
			})
			
			op.completionBlock = {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.count = self.count + 1
					self.delegate?.reportProgress(self, progress: self.count, total: urls.count)
					//self.progressIndicator.maxValue = 1
					//self.progressIndicator.doubleValue = (Double(self.count) / Double(urls.count))
					NSNotificationCenter.defaultCenter().postNotificationName(DataManager.DataManagerReportCompletionNotificationName, object: self)
				})
			}
			
			queue.addOperation(op)
		}
		queue.waitUntilAllOperationsAreFinished()
		
		let dcf = NSDateComponentsFormatter()
		
		let unit: NSCalendarUnit = [.Second, .Minute]
		dcf.allowedUnits = unit
		dcf.zeroFormattingBehavior = .DropAll
		dcf.allowsFractionalUnits = true
		dcf.unitsStyle = .Short
		let a = dcf.stringFromDate(start, toDate: NSDate())!
		
		print("\(count) valid articles including \(coordinates_count) with coordinates. Took \(a).")
	}

	var articles = Set<WikiArticle>()
	
	func doWork(a: String) {
		let workOperation = NSBlockOperation {
			self.work(a)
		}
		workOperation.completionBlock = {
			NSOperationQueue.mainQueue().addOperationWithBlock({
				self.delegate?.reportCompletion(self)
			})
		}
		let oq = NSOperationQueue()
		oq.qualityOfService = .Utility
		oq.addOperation(workOperation)

	}
	
	
	var count = 0
//	var tmp_array: [WikiArticle]?

	
	
}
