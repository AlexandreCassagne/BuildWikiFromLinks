//
//  MapVC.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 15/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa
import MapKit
class MapVC: NSViewController, MKMapViewDelegate {
	// MARK: Fields
	@IBOutlet var mapView: MKMapView!
	private var articles = Set<WikiLanguageArticles>()
	private lazy var rightImage: NSImage = {
		let image = NSImage(named: NSImageNameGoRightTemplate)!
		return image
	}()

	// MARK: Content Management
	private func addArticles(set : Set<WikiLanguageArticles>) {
		let new_articles = Set(set.filter { (article) -> Bool in
			if article.coordinates == nil { return false }
			else { return true }
		})
		let delta = new_articles.subtract(articles)
		articles = new_articles
		generateAnnotations(delta)
	}
	private func generateAnnotations(delta: Set<WikiLanguageArticles>) {
		for article in delta {
			let annotation = WikiAnnotation()
			annotation.coordinate = {
				let a = article.coordinates!
				return CLLocationCoordinate2D(latitude: Double(a["lat"]!), longitude: Double(a["lon"]!))
			}()
			
			annotation.article = article
			annotation.title = article.base_article.articleName
			
			NSOperationQueue.mainQueue().addOperationWithBlock {
				self.mapView.addAnnotation(annotation)
			}
		}
	}
	
	// MARK: MKMapViewDelegate
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "default")
		view.canShowCallout = true
		
		let theButton: NSButton = NSButton()
		theButton.setButtonType(NSButtonType.MomentaryPushInButton)
		theButton.bezelStyle = .CircularBezelStyle
		theButton.image = rightImage
		theButton.target = self
		theButton.action = #selector(showDetail)
		
		view.rightCalloutAccessoryView = theButton
		
		return view
	}
	
	// MARK: Action
	func showDetail() {
		guard let annotation = mapView.selectedAnnotations.first as? WikiAnnotation, let storyboard = self.storyboard else { return }
		let vc = storyboard.instantiateControllerWithIdentifier("DetailViewController") as! DetailVC
		self.presentViewControllerAsModalWindow(vc)
		
		vc.article = annotation.article
	}
	
	// MARK: NSViewController Overrides
	override func awakeFromNib() {
		mapView.delegate = self
		
		NSNotificationCenter.defaultCenter().addObserverForName("DataManagerReportCompletion", object: nil, queue: nil)
		{ (let a) in
			self.addArticles(DataManager.sharedManager.languageBasedArticles)
		}
	}
	override func viewDidLoad() {
		super.viewDidLoad()
	}
}
