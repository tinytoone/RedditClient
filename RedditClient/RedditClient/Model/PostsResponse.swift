//
//  PostsResponse.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation

protocol PostsResponse {
    var children: [Post]? { get }
}

struct RedditPostsResponse: Decodable {
    let children: [Post]?
    
    enum CodingKeys: String, CodingKey {
        case data
        case children
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.children = (try? dataContainer.decode([RedditPost].self, forKey: .children))?.compactMap({$0 as Post})
    }
}
