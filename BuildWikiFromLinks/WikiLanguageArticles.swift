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
	
	// MARK: - Constructors
	init?(baseArticle: WikiArticle) {
		self.articles.append(baseArticle)
		self.base_article = baseArticle
		
		guard let langLinks = baseArticle.otherLanguages else { return }
		for langLink in langLinks {
			if let localized = DataManager.sharedManager.lookup(langLink.1) {
				self.articles.append(localized)
			}
		}
	}
}


// MARK: Equatable
func ==(lhs: WikiLanguageArticles, rhs: WikiLanguageArticles) -> Bool {
	return lhs.hashValue == rhs.hashValue
}