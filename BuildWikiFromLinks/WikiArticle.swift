//
//  WikiArticle.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 14/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa
import MapKit

class WikiArticle: Hashable, CustomStringConvertible, NSCoding {
	
	init?(articleName: String, language: Language) {
		guard let validID = WikiArticle.validateArticle(articleName, language: language)
			else { return nil }
		self.pageID = validID.id
		self.articleName = validID.title
		self.language = language
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
	init(language aLanguage: Language, articleName anArticleName: String, pageID aPageID: Int) {
		language = aLanguage
		articleName = anArticleName
		pageID = aPageID
	}
	
	@objc func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeRootObject(self.toDictionary())
	}
	@objc required init?(coder: NSCoder) {
		if let dictionary = coder.decodeObject() as? [String: AnyObject] {
			self.pageID = dictionary["pageID"] as! Int
			self.articleName = dictionary["articleName"] as! String
			self.language = Language(rawValue: dictionary["language"] as! String)!
			self.coordinates = dictionary["coordinates"] as? Coordinates
			self.summary = dictionary["summary"] as? String
			self.otherLanguages = dictionary["otherLanguages"] as? [String: String]
		} else {
			return nil
		}
	}
	
	func toDictionary() -> [String: AnyObject] {
		var dictionary = [String: AnyObject]()
		
		dictionary["language"] = language.rawValue
		dictionary["pageID"] = pageID
		dictionary["coordinates"] = coordinates
		dictionary["articleName"] = articleName
		dictionary["summary"] = summary
		if let otherLanguages = self.otherLanguages { dictionary["otherLanguages"] = otherLanguages }
		
		return dictionary
	}
		
	var description: String { return "\(language), \(articleName), \(coordinates), \(otherLanguages?.keys.sort())" }
	var hashValue: Int { return pageID.hashValue ^ language.hashValue }
	
	var pageID: Int
	var language: Language
	var articleName: String
	
	enum Language: String {
		case fr = "fr"
		case en = "en"
		case es = "es"
		case de = "de"
		case it = "it"
		case ru = "ru"
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
		guard let normalizedTitle = ((pages.first!.1)["title"]) as? String
			else { return nil }
		
		return (pageid, normalizedTitle)
	}
	
	typealias Coordinates = [String: NSNumber]
	
	func populateFields() {
		_ = self.coordinates
		_ = self.summary
		_ = self.image
		_ = self.otherLanguages
	}

	lazy var otherLanguages: [String: String]? = {
		let url = WikiArticle.URLForCommand(self.language, pageID: self.pageID, commands: "prop=langlinks&llprop=url")
		
		let request = NSData(contentsOfURL: url)!
		
		guard let a = try? NSJSONSerialization.JSONObjectWithData(request, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject> else {
			print("Error loading language links for \(self.articleName, self.language)");
			return [:]
		}
		
		guard let pages = a["query"]?["pages"] as? [String: AnyObject] else { return nil }
		guard let item = pages["\(self.pageID)"] as? [String: AnyObject] else { return nil }
		guard let langLinks = item["langlinks"] as? [[String: String]] else { return nil }
		
		var ret = [String: String]()
		
		for langLink in langLinks {
			guard let lang = langLink["lang"], let url = langLink["url"] else { continue }
			guard let _ = Language(rawValue: lang), let _ = NSURL(string: url) else { continue }
			
			ret[lang] = url //itemURL
		}
		return ret
	}()
	lazy var coordinates: Coordinates? = {
		let contents = try! String(contentsOfURL: WikiArticle.URLForCommand(self.language, pageID: self.pageID, commands: "prop=coordinates"))
		
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
	lazy var image: NSURL? = {
		let url = WikiArticle.URLForCommand(self.language, pageID: self.pageID, commands: "prop=pageimages&piprop=name%7Coriginal")
		
		let a = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfURL: url)!, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
		
		
		guard let pages = ((a["query"]?["pages"])) as? Dictionary<String, AnyObject>
			else { return nil }
		guard let imageURL = (pages.first!.1)["thumbnail"]??["original"]! as? String
			else { return nil }
		return NSURL(string: imageURL)
		
	}()
	lazy var summary: String? = {
		let url = WikiArticle.URLForCommand(self.language, pageID: self.pageID, commands: "prop=extracts&exintro=&explaintext")
		let request = NSData(contentsOfURL: url)!
		
		guard let a = try? NSJSONSerialization.JSONObjectWithData(request, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject> else {
			print("Error loading summary for \(self.articleName, self.language)");
			return nil
		}
		
		
		if let text = ((a["query"]?["pages"] as? Dictionary<String, AnyObject>)?.first?.1["extract"]) {
			return text as? String
		}
		else {
			return nil
		}
		
	}()
	

}
extension WikiArticle {
	static func URLForCommand(language: Language, pageID: Int, commands: String) -> NSURL {
		let escapedString = "https://\(language.rawValue).wikipedia.org/w/api.php?action=query&format=json&pageids=\(pageID)&\(commands)"
		return NSURL(string: escapedString)!
	}
}
func ==(rhs: WikiArticle, lhs: WikiArticle) -> Bool {
	return rhs.language == lhs.language && rhs.articleName == lhs.articleName
}