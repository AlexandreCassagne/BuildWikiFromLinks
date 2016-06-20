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

	// MARK: Statics
	static let sharedManager = DataManager()
	static let DataManagerReportCompletionNotificationName = "DataManagerReportCompletion"

	// MARK: - Fields
	private let enableLanguageBasedArticles = true
	weak var delegate: DataManagerDelegate?
	
	func resetLBA(lba: Set<WikiLanguageArticles>) {
		articles.removeAll()
		languageBasedArticles = lba
		
		for wla in languageBasedArticles {
			for a in wla.articles {
				articles.insert(a)
			}
		}

		self.delegate?.reportCompletion(self)
	}
	
	var languageBasedArticles = Set<WikiLanguageArticles>()
	
	var urls = Set<String>()
	var articles = Set<WikiArticle>()
	
	var count = 0 // TODO: Remove this ...
	
	
	// MARK: - Body
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
	func lookup(url: String) -> WikiArticle? {
		let matches = self.articles.filter { (article) -> Bool in
			return article.pageURL.absoluteString == url
		}
		assert(matches.count < 2)
		if let match = matches.first { return match }
		else {
			guard let article = WikiArticle(string: url)
				else { return nil }
			self.addArticle(article)
			return article
		}
	}
	
	// MARK: - Private
	private func addArticle(article: WikiArticle) {
		guard !self.articles.contains(article)
			else { return }
		article.populateFields()
		self.articles.insert(article)
		
		if let langlinks = article.otherLanguages {
			for langlink in langlinks {
				guard let _ = WikiArticle.Language(rawValue: langlink.0)
					else { continue }
				let link = langlink.1
				self.lookup(link)
			}
		}
	}
	private func work(text: String) {
		let start = NSDate()
		
		let queue = NSOperationQueue()
		queue.qualityOfService = .Background
		queue.maxConcurrentOperationCount = 50
		
		count = 0
		
		text.enumerateLines { (line, stop) in
			self.urls.insert(line)
		}
		
		var coordinates_count = 0
		for line in urls {
			let op = NSBlockOperation(block: {
				guard let article = WikiArticle(string: line)
					else { return }
				if self.enableLanguageBasedArticles {
					if let languageBasedArticle = WikiLanguageArticles(baseArticle: article) {
						self.languageBasedArticles.insert(languageBasedArticle)
					}
				}
				
				self.addArticle(article)
				if article.coordinates != nil { coordinates_count += 1 }
			})
			
			op.completionBlock = {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.count = self.count + 1
					self.delegate?.reportProgress(self, progress: self.count, total: self.urls.count)
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
}
