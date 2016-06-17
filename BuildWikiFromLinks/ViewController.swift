//
//  ViewController.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 13/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

final class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, DataManagerDelegate {
	
	@IBOutlet var timeRemainingLabel: NSTextField!
	
	@IBOutlet var tableView : NSTableView!
	@IBOutlet var progressIndicator : NSProgressIndicator!
	override func viewDidLoad() {
		super.viewDidLoad()
		DataManager.sharedManager.delegate = self
		progressIndicator.maxValue = 1.0
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
		
		self.tableView.reloadData()
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
//		oq.waitUntilAllOperationsAreFinished()
		self.progressIndicator.indeterminate = true

		fieldEditor.string = ""
		return true
	}
	

	private func writeArray(array: [WikiArticle]) {
		var articles = [[String: AnyObject]]()
		for article in array {
			articles.append(article.toDictionary())
		}
		
		
//		NSKeyedArchiver.archiveRootObject(array, toFile: NSHomeDirectory().stringByAppendingString("/file.plist"))
		NSArray(array: articles).writeToFile(NSHomeDirectory().stringByAppendingString("/file.plist"), atomically: true)
		
		
		var groups = [[String: AnyObject]]()
		for article in DataManager.sharedManager.languageBasedArticles {
			groups.append(article.articles)
		}
		print(groups)
		NSArray(array: groups).writeToFile(NSHomeDirectory().stringByAppendingString("/groups.plist"), atomically: true)
	}
}

