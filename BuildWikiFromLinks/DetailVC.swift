//
//  DetailVC.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 15/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa
import MapKit

class DetailVC: NSViewController {
	// MARK: Fields & Outlets
	@IBOutlet var popup: NSPopUpButton!
	@IBOutlet var primary: NSTextField!
	@IBOutlet var summary: NSTextView!
	@IBOutlet var imageView: NSImageView!
	
	// MARK: -
	private var selectedArticle : WikiArticle? {
		didSet {
			_ = self.view
			primary.stringValue = selectedArticle?.articleName ?? ""
			summary.string = selectedArticle?.summary
			
			let queue = NSOperationQueue()
			queue.qualityOfService = .UserInitiated
			queue.addOperationWithBlock {
				guard let imageURL = self.selectedArticle?.image.first else {return}
				guard let data = NSData(contentsOfURL: imageURL) else { return }
				guard let image = NSImage(data: data) else { return }
				
				let desiredSize = self.imageView.frame.size
				let newImage = self.resizeImage(image, toMaxSize: desiredSize)
				
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.imageView.image = newImage
				})
			}
		}
	}
	
	var selectedLanguage: WikiArticle.Language? {
		didSet {
			let validArticles = self.article?.articles.filter({ (article) -> Bool in
				return article.language == self.selectedLanguage
			})
			guard let validArticle = validArticles?.first else { return }
			self.selectedArticle = validArticle
		}
	}
	var article: WikiLanguageArticles? {
		didSet {
			self.selectedLanguage = article?.articles.first?.language
			populateMenu()
		}
	}
	
	
	// MARK: -
	// MARK: Convenience
	private func resizeImage(image: NSImage, toMaxSize: CGSize) -> NSImage {
		let oldWidth = image.size.width;
		let oldHeight = image.size.height;
		
		let scaleFactor = (oldWidth > oldHeight) ? toMaxSize.width / oldWidth : toMaxSize.height / oldHeight;
		
		let newHeight = oldHeight * scaleFactor;
		let newWidth = oldWidth * scaleFactor;
		let newSize = CGSizeMake(newWidth, newHeight);
		
		return resizeImageGenerate(image, toSize: newSize)
	}
	private func resizeImageGenerate(image: NSImage, toSize: CGSize) -> NSImage {
		let newImage = NSImage(size: toSize)
		newImage.lockFocus()
		image.drawInRect(CGRectMake(0, 0, toSize.width, toSize.height))
		newImage.unlockFocus()
		return newImage;
	}
	private func populateMenu() {
		guard let article = article else { return }
		popup.removeAllItems()
		for language in article.languages {
			popup.addItemWithTitle(language.rawValue)
		}
	}
	
	// MARK: -
	// MARK: NSPopupButton Action
	func select() {
		guard let selected = popup.selectedItem?.title else { return }
		self.selectedLanguage = WikiArticle.Language(rawValue: selected)!
	}
	
	
	// MARK: NSViewController Overrides
	override func viewDidLoad() {
		super.viewDidLoad()
		popup.target = self
		popup.action = #selector(DetailVC.select)
		popup.removeAllItems()
	}
	
}
