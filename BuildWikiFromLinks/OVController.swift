//
//  OVController.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 17/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

class OVController: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {
	var articles: [WikiLanguageArticles]?
	
	@IBOutlet var outlineView: NSOutlineView!
	
	func reload() {
		articles = DataManager.sharedManager.languageBasedArticles
		outlineView.reloadData()
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
			if tableColumn?.identifier == "coordinates_column" {
				view = outlineView.makeViewWithIdentifier("coordinates_cell", owner: self) as? NSTableCellView
				text = languageArticle.languages
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
		return view
	}
	
}
