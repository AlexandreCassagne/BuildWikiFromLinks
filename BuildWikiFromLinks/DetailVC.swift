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

	@IBOutlet var primary: NSTextField!
	@IBOutlet var summary: NSTextView!
	@IBOutlet var imageView: NSImageView!
	
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
	
	var article: WikiArticle? {
		didSet {
			self.loadView()
			primary.stringValue = article?.articleName ?? ""
			summary.string = article?.summary
			
			let queue = NSOperationQueue()
			queue.qualityOfService = .UserInitiated
			queue.addOperationWithBlock {
				guard let imageURL = self.article?.image else {return}
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
	
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
