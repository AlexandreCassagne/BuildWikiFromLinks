//
//  ViewController.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 13/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate, DataManagerDelegate {
	
	@IBOutlet var timeRemainingLabel: NSTextField!
	
	@IBOutlet var tableView : NSOutlineView!
	@IBOutlet var progressIndicator : NSProgressIndicator!
		
	override func viewDidLoad() {
		super.viewDidLoad()
		DataManager.sharedManager.delegate = self
		progressIndicator.maxValue = 1.0
		
		
		
		// Do any additional setup after loading the view.
	}
	
	private var tmp_array: [WikiArticle]?
	
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

	
	private var beginDate: NSDate?
	private var averageTimeInterval: NSTimeInterval = 0
	private var lastProgress: NSDate?
	private let smoothing_factor = 0.03
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
	
	lazy var dcf: NSDateComponentsFormatter = {
		let dcf = NSDateComponentsFormatter()
		
		let unit: NSCalendarUnit = [.Second, .Minute, .Hour]
		dcf.allowedUnits = unit
		dcf.zeroFormattingBehavior = .DropAll
		dcf.allowsFractionalUnits = true
		dcf.unitsStyle = .Full
		return dcf
	}()
	
	func reportProgress(sender: DataManager, progress: Int, total: Int) {
		let ti = self.calculateTimeRemaining(progress, total: total)
		if isinf(ti) { return }
		timeRemainingLabel.stringValue = dcf.stringFromTimeInterval(ti) ?? ""
		
		self.progressIndicator.indeterminate = false
		self.progressIndicator.doubleValue = Double(progress) / Double(total)
	}
	
	func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		guard let a = fieldEditor.string else { return true }
		
		DataManager.sharedManager.doWork(a)
		self.progressIndicator.indeterminate = true

		fieldEditor.string = ""
		return true
	}
	

	private func writeArray(array: [WikiArticle]) {
		var articles = [[String: AnyObject]]()
		for article in array {
			articles.append(article.toDictionary())
		}
	}
	
	
	var articles: [WikiLanguageArticles]?
	func reload() {
		articles = DataManager.sharedManager.languageBasedArticles
		tableView.reloadData()
	}
	
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
				text = languageArticle.english_article.articleName
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
		}
		
		view?.textField?.stringValue = text ?? ""
		view?.textField?.sizeToFit()
		return view
	}

	
}

