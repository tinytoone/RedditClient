//
//  RedditAPIProvider.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation

protocol APIEndpoint {
    static var baseURLPath: String { get }
    var absoluteURLPath: String { get }
    var relativeURLPath: String { get }
    var url: URL { get }
}

struct GetTopRedditEndpoint: APIEndpoint {
    static let baseURLPath = "https://www.reddit.com"

    let limit: Int
    let afterArticleId: String?
    
    let absoluteURLPath: String
    let relativeURLPath: String
    let url: URL

    init(limit: Int, afterArticleId: String?) {
        self.limit = limit
        self.afterArticleId = afterArticleId
        
        var relativePath = "/top.json?limit=\(self.limit)"
        if let afterArticleId = self.afterArticleId {
            relativePath += relativePath + "&after=\(afterArticleId)"
        }
        self.relativeURLPath = relativePath
        
        self.absoluteURLPath = GetTopRedditEndpoint.baseURLPath + self.relativeURLPath
        self.url = URL(string: self.absoluteURLPath)!
    }
}
