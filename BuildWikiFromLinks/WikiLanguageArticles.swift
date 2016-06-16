//
//  WikiLanguageArticles.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 16/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa

class WikiLanguageArticles {
	
	var articles = [WikiArticle]()
	
	init(baseArticle: WikiArticle) {
		self.articles.append(baseArticle)
		
		guard let langLinks = baseArticle.otherLanguages else { return }
		for langLink in langLinks {
			DataManager.sharedManager.lookup(langLink.1)
		}
		
	}
	
	
}
