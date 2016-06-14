//
//  ViewController.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 13/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
	
	@IBOutlet var tableView : NSTableView!
	@IBOutlet var progressIndicator : NSProgressIndicator!
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
		var cellIdentifier: String = ""
		var text: String?
		
		guard let article = tmp_array?[row] else { return nil }
		
		if tableColumn == tableView.tableColumns[0] {
			cellIdentifier = "idCellID"
			text = article.hashValue.description
		}
		
		if tableColumn == tableView.tableColumns[1] {
			cellIdentifier = "LanguageCellID"
			text = article.language.rawValue
			
		} else if tableColumn == tableView.tableColumns[2] {
			cellIdentifier = "ArticleNameCellID"
			text = article.articleName
		} else if tableColumn == tableView.tableColumns[3] {
			text = article.coordinates?.description ?? ""
			cellIdentifier = "CoordinatesCellID"
		}
		
		if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
			cell.textField?.stringValue = text!
			return cell
		}
		return nil
	}
	
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return tmp_array?.count ?? 0
	}
	
	var articles = Set<WikiArticle>()

	private func work(text: String) {
		let queue = NSOperationQueue()
		queue.qualityOfService = .Background
		queue.maxConcurrentOperationCount = 25
		
		count = 0
		
		var urls = Set<String>()
		text.enumerateLines { (line, stop) in
			urls.insert(line)
		}
		/*
		text.enumerateLines { (line, stop) in
			self.count = self.count + 1

			guard let article = WikiArticle(string: line)	else { return }
			guard !self.articles.contains(article)			else { return }
			
			
			let op = NSBlockOperation(block: {
				article.populateFields()
				
				if article.coordinates == nil { return }
				self.articles.insert(article)
				
			})
			
			op.completionBlock = {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.progressIndicator.maxValue = 1
					self.progressIndicator.doubleValue = (Double(self.count) / Double(urls.count))
				})
			}
			
			
			queue.addOperation(op)
		} */
		for line in urls {
			
			guard let article = WikiArticle(string: line)	else { return }
			guard !self.articles.contains(article)			else { return }
			
			
			let op = NSBlockOperation(block: {
				article.populateFields()
				
				if article.coordinates == nil { return }
				self.articles.insert(article)
				
			})
			
			op.completionBlock = {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.count = self.count + 1
					print(self.count)
					self.progressIndicator.maxValue = 1
					self.progressIndicator.doubleValue = (Double(self.count) / Double(urls.count))
					
				})
			}
			
			queue.addOperation(op)
		}
		queue.waitUntilAllOperationsAreFinished()
		
	}
	
	func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		guard let a = fieldEditor.string else { return true }
		
		let workOperation = NSBlockOperation {
			self.work(a)
		}
		workOperation.completionBlock = {
			NSOperationQueue.mainQueue().addOperationWithBlock({
				self.tmp_array = nil
				self.tmp_array = Array(self.articles)
				self.tableView.reloadData()
				
				self.writeArray(self.tmp_array!)
				print("Done!")
			})
		}
		let oq = NSOperationQueue()
		oq.qualityOfService = .Background
		oq.addOperation(workOperation)
		
		
		//		queue.waitUntilAllOperationsAreFinished()
		
		fieldEditor.string = ""
		return true
	}
	
	var count = 0
	var tmp_array: [WikiArticle]?

	private func writeArray(array: [WikiArticle]) {
		var articles = [[String: AnyObject]]()
		for article in array {
			articles.append(article.toDictionary())
		}
		print(array.count)
		NSArray(array: articles).writeToFile(NSHomeDirectory().stringByAppendingString("/file.plist"), atomically: true)
	}
}

