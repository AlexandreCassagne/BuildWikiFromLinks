//
//  ViewController.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 13/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

final class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, DataManagerDelegate {
	
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
			let result = a.articleName.compare(b.articleName)
			return result == .OrderedAscending
		}
		
		self.tableView.reloadData()
		self.writeArray(self.tmp_array!)
		print("Done!")

	}

	func reportProgress(sender: DataManager, progress: Int, total: Int) {
		self.progressIndicator.doubleValue = Double(progress) / Double(total)
	}
	
	func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		guard let a = fieldEditor.string else { return true }
		
		DataManager.sharedManager.doWork(a)
//		oq.waitUntilAllOperationsAreFinished()
		
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
	}
}

