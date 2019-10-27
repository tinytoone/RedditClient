//
//  RedditPost.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation

protocol Post {
    var id: String { get }
    var title: String { get }
    var author: String { get }
    var dateCreated: Date { get }
    var hidden: Bool { get }
    var thumbnailURL: URL? { get }
    var commentsCount: Int { get }
    var originalImageURL: URL? { get }
}

struct RedditPost: Post, Decodable {
    let id: String
    let title: String
    let author: String
    let dateCreated: Date
    let hidden: Bool
    let thumbnailURL: URL?
    let commentsCount: Int
    let originalImageURL: URL?
    private let preview: Preview?

    enum CodingKeys: String, CodingKey {
        case data
        case title
        case author
        case createdUtc = "created_utc"
        case hidden
        case name
        case thumbnail
        case preview
        case numComments = "num_comments"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.id = try dataContainer.decode(String.self, forKey: .name)
        self.title = try dataContainer.decode(String.self, forKey: .title)
        self.author = try dataContainer.decode(String.self, forKey: .author)
        let timeUtc = try dataContainer.decode(TimeInterval.self, forKey: .createdUtc)
        self.dateCreated = Date(timeIntervalSince1970: timeUtc)
        self.hidden = try dataContainer.decode(Bool.self, forKey: .hidden)
        self.commentsCount = (try? dataContainer.decode(Int.self, forKey: .numComments)) ?? 0
        self.thumbnailURL = try? dataContainer.decode(URL.self, forKey: .thumbnail)
        self.preview = try? dataContainer.decode(Preview.self, forKey: .preview)
        self.originalImageURL = preview?.images?.first?.source?.url // Pick first image as main post image
    }
}

// MARK: - Helper structs
// MARK: Preview
private struct Preview: Codable {
    let images: [Image]?
}

// MARK: Image
private struct Image: Codable {
    let source: Source?
}

// MARK: Source
private struct Source: Codable {
    let url: URL?
}
