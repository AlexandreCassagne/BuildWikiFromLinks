//
//  WikiLanguageArticles.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 16/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa



class WikiLanguageArticles: CustomStringConvertible{
	let english_article : WikiArticle
	var articles = [String: WikiArticle]()
	
	var description: String {
		return articles.description
	}
	
	init?(baseArticle: WikiArticle) {
		self.articles[baseArticle.language.rawValue] = baseArticle
		
		english_article = baseArticle
		if english_article.language != .en { return nil }
		
		guard let langLinks = baseArticle.otherLanguages else { return }
		for langLink in langLinks {
			let localized = DataManager.sharedManager.lookup(langLink.1)
			articles[langLink.0] = localized
		}
		
	}
	
	
}
