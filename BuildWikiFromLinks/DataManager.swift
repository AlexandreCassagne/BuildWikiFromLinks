//
//  DataManager.swift
//  BuildWikiFromLinks
//
//  Created by Alexandre Cassagne on 15/06/2016.
//  Copyright © 2016 Alexandre Cassagne. All rights reserved.
//

import Cocoa
import SQLite

protocol DataManagerDelegate: class {
	func reportProgress(sender: DataManager, progress: Int, total: Int)
	func reportCompletion(sender: DataManager)
}
class DataManager {
	let db = try! Connection("/Users/Alexandre/Desktop/chateaux.sqlite")
	
	var articles: Set<WikiArticle>?
	var dictionary = [String: WikiArticle]()
	
	struct Objects {
		static let chateaux = Table("chateaux")
		static let url = Expression<String>("url")
		static let language = Expression<String>("language")
		static let articleName = Expression<String>("article_name")
		static let otherLanguages = Expression<String>("other_languages")
		static let images = Expression<String>("images")
		static let pageID = Expression<Int>("pageID")
		
		//optionals
		static let summary = Expression<String?>("summary")
		
		static let latitude = Expression<Double?>("latitude")
		static let longitude = Expression<Double?>("longitude")
		
	}
	init() {
		try! db.run(Objects.chateaux.create(ifNotExists: true) { t in
			t.column(Objects.url, primaryKey: true)
			t.column(Objects.language)
			t.column(Objects.articleName)
			t.column(Objects.latitude)
			t.column(Objects.longitude)
			t.column(Objects.otherLanguages)
			t.column(Objects.images)
			t.column(Objects.summary)
			t.column(Objects.pageID)
			t.unique([Objects.language, Objects.pageID])
			})
		
		buildWiki()
		
		delegate?.reportCompletion(self)
	}
	
	func buildWiki() {
		let table = try! db.prepare(Objects.chateaux)
		articles = Set(table.map { (row) -> WikiArticle in return self.rowToArticle(row) })
		
		guard let articles = articles else { fatalError() }
		let bases = articles.filter { article -> Bool in return article.language == WikiArticle.Language.BaseLanguage}
		
		for article in articles {
			let link = article.pageURL.absoluteString
			dictionary[link] = article
		}
		
		for base in bases {
			
			var lang_dic = [WikiArticle.Language.BaseLanguage: base]
			for (language_string, link_string) in base.otherLanguages {
				guard let a = self.dictionary[link_string] else { continue }
				let lang = WikiArticle.Language(rawValue: language_string)!
				lang_dic[lang] = a
			}
			let lba = WikiLanguageArticles(dictionary: lang_dic, base: base.language)
			self.languageBasedArticles.insert(lba)
			
		}
	}
	
	// MARK: Statics
	static let sharedManager = DataManager()
	static let DataManagerReportCompletionNotificationName = "DataManagerReportCompletion"
	
	// MARK: - Fields
	private let enableLanguageBasedArticles = true
	weak var delegate: DataManagerDelegate?
	
	func rowToArticle(row: Row) -> WikiArticle {
		var coord: WikiArticle.Coordinates? = nil
		let (lat, lon) = (row[Objects.latitude], row[Objects.longitude])
		if let lat = lat, let lon = lon {
			coord = ["lat": lat, "lon": lon]
		}
		
		
		let pageurl = NSURL(string: row[Objects.url])!
		let images = row[Objects.images].componentsSeparatedByString("\n").flatMap { (link) -> NSURL? in
			return NSURL(string: link)
		}
		
		
		
		var language_dict = [String: String]()
		let other_languages_raw = row[Objects.otherLanguages].componentsSeparatedByString("\n")
		for other_language in other_languages_raw {
			let ol_array = other_language.componentsSeparatedByString("::")
			guard ol_array.count == 2 else { continue }
			let language = ol_array[0]
			let url = ol_array[1]
			language_dict[language] = url
		}
		
		
		let lang = WikiArticle.Language(rawValue: row[Objects.language])!
		
		let article = WikiArticle(language: lang, articleName: row[Objects.articleName], pageID: row[Objects.pageID], pageURL: pageurl, coordinates: coord, otherLanguages: language_dict, image: images, summary: row[Objects.summary])
		
		return article
	}
	
	
	var languageBasedArticles = Set<WikiLanguageArticles>()
	var count = 0 // TODO: Remove this ...
	
	
	
	// MARK: - Body
	func doWork(a: String) {
		let workOperation = NSBlockOperation {
			self.work(a)
		}
		workOperation.completionBlock = {
			NSOperationQueue.mainQueue().addOperationWithBlock({
				self.delegate?.reportCompletion(self)
			})
		}
		let oq = NSOperationQueue()
		oq.qualityOfService = .Utility
		oq.addOperation(workOperation)
	}
	
	func lookup(url: String) -> WikiArticle? {
		if let articles = articles {
			let tmp = articles.filter({ article -> Bool in article.pageURL.absoluteString == url })
			if tmp.count == 1 { return tmp.first! }
		}
		let rows = try! db.prepare(Objects.chateaux).filter({ (battle) -> Bool in return battle[Objects.url] == url })
		//		print(rows.first)
		if let row = rows.first {
			return self.rowToArticle(row)
		}
		else {
			if let article = WikiArticle(string: url) {
				self.addArticle(article)
				return article
			} else {
				return nil
			}
		}
	}
	
	private func addArticle(article: WikiArticle) {
		article.populateFields()
		
		let images = article.image.reduce("", combine: { (initial, next) -> String in
			return "\(initial) \(next.absoluteString)"
		})
		
		var other_languages_string = String()
		for (language, link) in article.otherLanguages {
			other_languages_string.appendContentsOf("\(language)::\(link)\n")
		}
		
		let url = article.pageURL.absoluteString
		
		let lat = article.coordinates?["lat"] as? Double
		let lon = article.coordinates?["lon"] as? Double
		
		let insert = Objects.chateaux.insert([Objects.language <- article.language.rawValue, Objects.url <- url, Objects.articleName <- article.articleName, Objects.images <- images, Objects.pageID <- article.pageID, Objects.summary <- article.summary, Objects.otherLanguages <- other_languages_string, Objects.latitude <- lat, Objects.longitude <- lon])
		
		try? self.db.run(insert)
	}
	
	private func work(text: String) {
		let start = NSDate()
		
		let queue = NSOperationQueue()
		queue.qualityOfService = .UserInteractive
		queue.maxConcurrentOperationCount = 50
		
		count = 0
		var urls = Set<String>()
		text.enumerateLines { (line, stop) in
			urls.insert(line)
		}

		let query = Objects.chateaux.select(Objects.url)
		for row in try! db.prepare(query) {
			urls.remove(row[Objects.url])
		}
		
		var coordinates_count = 0
		for line in urls {
			let op = NSBlockOperation(block: {
				guard let article = self.lookup(line)
					else { return }
				if self.enableLanguageBasedArticles {
					let languageBasedArticle = WikiLanguageArticles(baseArticle: article)
					self.languageBasedArticles.insert(languageBasedArticle)
				}
				
				if article.coordinates != nil { coordinates_count += 1 }
			})
			
			op.completionBlock = {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.count = self.count + 1
					self.delegate?.reportProgress(self, progress: self.count, total: urls.count)
					NSNotificationCenter.defaultCenter().postNotificationName(DataManager.DataManagerReportCompletionNotificationName, object: self)
				})
			}
			queue.addOperation(op)
		}
		queue.waitUntilAllOperationsAreFinished()
		
		let dcf = NSDateComponentsFormatter()
		
		let unit: NSCalendarUnit = [.Second, .Minute]
		dcf.allowedUnits = unit
		dcf.zeroFormattingBehavior = .DropAll
		dcf.allowsFractionalUnits = true
		dcf.unitsStyle = .Short
		let a = dcf.stringFromDate(start, toDate: NSDate())!
		
		print("\(count) valid articles including \(coordinates_count) with coordinates. Took \(a).")
	}
}
