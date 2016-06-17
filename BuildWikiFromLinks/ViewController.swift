//
//  ViewController.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 13/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate, DataManagerDelegate {
	
	// MARK: Fields & Outlets
	@IBOutlet var timeRemainingLabel: NSTextField!
	@IBOutlet var tableView : NSOutlineView!
	@IBOutlet var progressIndicator : NSProgressIndicator!
	
	var articles: [WikiLanguageArticles]?
	private var tmp_array: [WikiArticle]? // TODO: Remove this
	

	// MARK: Time Remaining Fields
	// Could be removed; not essential.
	private var beginDate: NSDate?
	private var averageTimeInterval: NSTimeInterval = 0
	private var lastProgress: NSDate?
	private let smoothing_factor = 0.03
	lazy var dcf: NSDateComponentsFormatter = {
		let dcf = NSDateComponentsFormatter()
		
		let unit: NSCalendarUnit = [.Second, .Minute, .Hour]
		dcf.allowedUnits = unit
		dcf.zeroFormattingBehavior = .DropAll
		dcf.allowsFractionalUnits = true
		dcf.unitsStyle = .Full
		return dcf
	}() // Date formatter for
	
	
	// MARK: - DataManagerDelegate
	func reportCompletion(sender: DataManager) {
		tmp_array = Array(sender.articles)
		
		tmp_array!.sortInPlace { (a, b) -> Bool in
			let first = a.language.rawValue.compare(b.language.rawValue)
			if first == NSComparisonResult.OrderedSame {
				let result = a.articleName.compare(b.articleName)
				return result == .OrderedAscending
			}
			else {
				return first == .OrderedAscending
			}
		}
		
		averageTimeInterval = 0
		lastProgress = nil
		
		let interval = -beginDate!.timeIntervalSinceNow
		let a = dcf.stringFromTimeInterval(interval)
		
		timeRemainingLabel.stringValue = "Done! Pulled \(sender.articles.count) articles in \(a ?? "(unknown time)")."
		
		beginDate = nil
		
		//self.tableView.reloadData()
		self.reload()
		self.writeArray(self.tmp_array!)
		print("Done!")
		
	}
	func reportProgress(sender: DataManager, progress: Int, total: Int) {
		let ti = self.calculateTimeRemaining(progress, total: total)
		if isinf(ti) { return }
		timeRemainingLabel.stringValue = dcf.stringFromTimeInterval(ti) ?? ""
		
		self.progressIndicator.indeterminate = false
		self.progressIndicator.doubleValue = Double(progress) / Double(total)
	}
	
	// MARK: -
	private func calculateTimeRemaining(done: Int, total: Int) -> NSTimeInterval {
		guard let _lastProgress = lastProgress, let _ = beginDate else {
			beginDate = NSDate()
			lastProgress = NSDate()
			return NSTimeInterval.infinity
		}
		averageTimeInterval = smoothing_factor * (-_lastProgress.timeIntervalSinceNow) + (1 - smoothing_factor) * averageTimeInterval;
		lastProgress = NSDate()
		return averageTimeInterval * NSTimeInterval(total - done)
	}
	
	
	// MARK: - NSTextFieldDelegate
	func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		guard let a = fieldEditor.string else { return true }
		
		DataManager.sharedManager.doWork(a)
		self.progressIndicator.indeterminate = true
		
		fieldEditor.string = ""
		return true
	}
	
	
	// MARK: - Private
	private func writeArray(array: [WikiArticle]) {
		var articles = [[String: AnyObject]]()
		for article in array {
			articles.append(article.toDictionary())
		} // TODO: broken
	}
	
	
	private func reload() {
		articles = Array(DataManager.sharedManager.languageBasedArticles)
		
		articles?.sortInPlace({ (a, b) -> Bool in
			if a.coordinates != nil { return true}
			else { return false }
		})
		
		tableView.reloadData()
	}
	
	// MARK: - NSOutlineView Datasource & Delegate
	func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
		if item == nil { return self.articles?.count ?? 0 }
		else if let item = item as? WikiLanguageArticles {
			return item.articles.count
		}
		return 0
	}
	func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
		if let item = item as? WikiLanguageArticles {
			return item.articles[index]
		}
		return articles![index]
	}
	func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
		if let item = item as? WikiLanguageArticles { return item.articles.count > 0 }
		else { return false }
	}
	func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
		var view: NSTableCellView?
		var text: String?
		
		if let languageArticle = item as? WikiLanguageArticles {
			if tableColumn?.identifier == "article_name_column" {
				view = outlineView.makeViewWithIdentifier("article_name_cell", owner: self) as? NSTableCellView
				text = languageArticle.base_article.articleName
			}
			else if tableColumn?.identifier == "coordinates_column" {
				view = outlineView.makeViewWithIdentifier("coordinates_cell", owner: self) as? NSTableCellView
				text = languageArticle.coordinates?.description
			}
			else if tableColumn?.identifier == "language_column" {
				view = outlineView.makeViewWithIdentifier("language_cell", owner: self) as? NSTableCellView
				text = ""
				for i in languageArticle.languages {
					text!.appendContentsOf("\(i.rawValue) ")
				}
			}
		}
			
		else if let article = item as? WikiArticle {
			if tableColumn?.identifier == "id_column" {
				view = outlineView.makeViewWithIdentifier("id_cell", owner: self) as? NSTableCellView
				text = article.pageID.description
			}
			else if tableColumn?.identifier == "article_name_column" {
				view = outlineView.makeViewWithIdentifier("article_name_cell", owner: self) as? NSTableCellView
				text = article.articleName
			}
			else if tableColumn?.identifier == "coordinates_column" {
				view = outlineView.makeViewWithIdentifier("coordinates_cell", owner: self) as? NSTableCellView
				text = article.coordinates?.description ?? ""
			}
			else if tableColumn?.identifier == "language_column" {
				view = outlineView.makeViewWithIdentifier("language_cell", owner: self) as? NSTableCellView
				text = article.language.rawValue
			}
		}
		
		view?.textField?.stringValue = text ?? ""
		return view
	}
	
	// MARK: NSViewController Overrides
	override func viewDidLoad() {
		super.viewDidLoad()
		DataManager.sharedManager.delegate = self
		progressIndicator.maxValue = 1.0
	}

}

