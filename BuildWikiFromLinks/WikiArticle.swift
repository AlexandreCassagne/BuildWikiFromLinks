//
//  WikiArticle.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 14/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa
import MapKit

class WikiArticle: Hashable, CustomStringConvertible {
	
	func toDictionary() -> [String: AnyObject] {
		var dictionary = [String: AnyObject]()
		
		dictionary["language"] = language.rawValue
		dictionary["pageID"] = pageID
		dictionary["coordinates"] = coordinates
		dictionary["articleName"] = articleName
		
		
		return dictionary
	}
	
	/*
	func encodeWithCoder(aCoder: NSCoder) {
		var dictionary = [String: AnyObject]()
		
		dictionary["language"] = language.rawValue
		dictionary["pageID"] = pageID
		dictionary["coordinates"] = coordinates
		dictionary["articleName"] = articleName
		
		aCoder.encodeRootObject(dictionary)
	}
	
	required init?(coder: NSCoder) {
		
		guard let lan_str = coder.decodeObjectForKey("language") as? String else { return nil }
		guard let articleName = coder.decodeObjectForKey("articleName") as? String else { return nil }
		guard let _pageid = coder.decodeObjectForKey("pageID") as? Int else { return nil }
		
		
		self.pageID = _pageid
		self.language = Language(rawValue: lan_str)!
		self.articleName = articleName
		
		super.init()
		
		if let coordinates = coder.decodeObjectForKey("coordinates") as? Coordinates {
			self.coordinates = coordinates
		}

	}
	*/
	init(language aLanguage: Language, articleName anArticleName: String, pageID aPageID: Int) {
		language = aLanguage
		articleName = anArticleName
		pageID = aPageID
	}
	
	var description: String {
		return "\(language), \(articleName), \(coordinates)"
	}
	
	var hashValue: Int {
	//	return articleName.hashValue ^ language.hashValue
		return pageID.hashValue ^ language.hashValue
	}
	var pageID: Int
	
	enum Language: String {
		case fr = "fr"
		case en = "en"
	}
	
	private static func validateArticle(articleName: String, language: Language) -> (id: Int, title: String)? {
		let escapedString = "https://\(language.rawValue).wikipedia.org/w/api.php?action=query&format=json&redirects&titles=\(articleName)"
		let url = NSURL(string: escapedString)!
		let contents = try! String(contentsOfURL: url)

		guard let a = try? NSJSONSerialization.JSONObjectWithData((contents).dataUsingEncoding(NSUnicodeStringEncoding)!, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
			else { return nil }
		
		guard let pages = ((a["query"]?["pages"])) as? Dictionary<String, AnyObject>
			else { return nil }
		
		guard let pageid = ((pages.first!.1)["pageid"]) as? Int
			else { return nil}
		
		guard let normalizedTitle = ((pages.first!.1)["title"]) as? String else { return nil }
		
		return (pageid, normalizedTitle)
		
	}
	
	init?(string: String) {
		let matcher =  "https:\\/\\/(en|fr).wikipedia.org\\/wiki\\/(.*)"
		
		guard let _ = NSURL(string: string)
			else {return nil}
		
		let r = try! NSRegularExpression(pattern: matcher, options: .UseUnixLineSeparators)
		
		guard let match = r.firstMatchInString(string, options: .Anchored, range: NSMakeRange(0, NSString(string: string).length))
			else { return nil }
		
		let r1 = match.rangeAtIndex(2), r2 = match.rangeAtIndex(1)
		let s1 = NSString(string: string).substringWithRange(r1), s2 = NSString(string: string).substringWithRange(r2)
		
		self.language = Language(rawValue: s2)!
		self.articleName = s1
		
		guard let validID = WikiArticle.validateArticle(self.articleName, language: self.language) else { return nil }
		self.pageID = validID.id
		self.articleName = validID.title
	}
	
	//	let pageID: NSString
	
	var language: Language
	var articleName: String
	
	
	
	
	typealias Coordinates = [String: NSNumber]
	lazy var coordinates: Coordinates? = {
		
		//let escapedString = "https://\(self.language).wikipedia.org/w/api.php?action=query&format=json&prop=coordinates&titles=\(self.articleName.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)&redirects"
		let escapedString = "https://\(self.language).wikipedia.org/w/api.php?action=query&format=json&prop=coordinates&pageids=\(self.pageID)"
		let url = NSURL(string: escapedString)!
		let contents = try! String(contentsOfURL: url)
		
		guard let a = try? NSJSONSerialization.JSONObjectWithData((contents).dataUsingEncoding(NSUnicodeStringEncoding)!, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
			else { return nil }
		
		guard let pages = ((a["query"]?["pages"])) as? Dictionary<String, AnyObject>
			else { return nil }
		
		guard let coords = ((pages.first!.1)["coordinates"]) as? Array<AnyObject>
			else { return nil}
		
		guard let coord = coords.first as? [String: AnyObject]
			else { return nil }
		
		let (lat, lon) = (coord["lat"]!, coord["lon"]!)
		guard let lat_d = lat as? NSNumber, let lon_d = lon as? NSNumber
			else { return nil}
		
		return ["lat": lat_d, "lon": lon_d]
	}()
	
	func populateFields() {
		let _ = self.coordinates
	}
}

func ==(rhs: WikiArticle, lhs: WikiArticle) -> Bool {
	return rhs.language == lhs.language && rhs.articleName == lhs.articleName
}