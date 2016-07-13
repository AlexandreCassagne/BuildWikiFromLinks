//
//  WikiLanguageArticles.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 16/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

class WikiLanguageArticles: CustomStringConvertible, Hashable, Equatable {
	// MARK: Fields
	let base_article : WikiArticle
	var articles = [WikiArticle]()
	
	var languages: [WikiArticle.Language] {
		return articles.map {
			article -> WikiArticle.Language in
			return article.language
		}
	}
	var coordinates: WikiArticle.Coordinates? {
		for article in articles {
			if let ret = article.coordinates {
				return ret
			}
		}
		return nil
	}

	// MARK: Protocols
	// MARK: Hashable
	var hashValue: Int { return base_article.hashValue }
	// MARK: CustomStringConvertible
	var description: String {
		return articles.description
	}
	
	init(dictionary: [WikiArticle.Language : WikiArticle], base: WikiArticle.Language) {
		self.base_article = dictionary[base]!
		articles = Array(dictionary.values)
	}
	
	// MARK: - Constructors
	init(baseArticle: WikiArticle) {
		self.articles.append(baseArticle)
		self.base_article = baseArticle
		
		for langLink in baseArticle.otherLanguages {
			if let localized = DataManager.sharedManager.lookup(langLink.1) {
				self.articles.append(localized)
			}
		}
	}
	
	// MARK: - Dictionary Value
	func toDictionary() -> [String: AnyObject] {
		var dict = [String: AnyObject]()
		dict["base"] = base_article.toDictionary()
		dict["articles"] = articles.map { (article) -> [String: AnyObject] in return article.toDictionary() }
		dict["coordinates"] = self.coordinates
		dict["languages"] = self.languages.map { (language) -> String in return language.rawValue }
		
		return dict
	}
	
	init?(from dictionary: [String: AnyObject]) {
		base_article = WikiArticle(from: dictionary["base"] as! [String: AnyObject])!
		articles = (dictionary["articles"] as! [[String: AnyObject]]).map { value -> WikiArticle in
			return WikiArticle(from: value)!
		}
	}
}

// MARK: Equatable
func ==(lhs: WikiLanguageArticles, rhs: WikiLanguageArticles) -> Bool {
	return lhs.hashValue == rhs.hashValue
}