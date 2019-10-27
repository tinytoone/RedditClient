//
//  PostsListViewModel.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation
import UIKit.UIImage

protocol PostsListViewModel {
    var apiClient: APIClient { get }
    var postsListChanged: ([PostDisplayItem]) -> () { get set }
    init(apiClient: APIClient)
    var postsDisplayItems: [PostDisplayItem] { get }
    
    func getTopPosts()
}

class RedditPostsListViewModel : PostsListViewModel {
    let apiClient: APIClient
    var postsListChanged: ([PostDisplayItem]) -> () = {_ in}
    private(set) var postsDisplayItems = [PostDisplayItem]() {
        didSet {
            postsListChanged(postsDisplayItems)
        }
    }

    required init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func getTopPosts() {
        guard !postsListLoadIsInProgress else {
            return
        }
        postsListLoadIsInProgress = true
        apiClient.performRequest(endpoint: GetTopRedditEndpoint(limit: RedditPostsListViewModel.postsChunkLimit, afterPostId: currentLastPostId)) {[weak self] (data, error) in
            guard let self = self else {
                return
            }
            guard let data = data else {
                self.postsListLoadIsInProgress = false
                return
            }
            let redditPostResponse = try? JSONDecoder().decode(RedditPostsResponse.self, from: data)
            guard let recentPosts = redditPostResponse?.children, recentPosts.count > 0 else {
                self.postsListLoadIsInProgress = false
                return
            }
            self.posts = self.posts + recentPosts
            self.postsDisplayItems = self.posts.map{ PostDisplayItem(post: $0) }
            self.currentLastPostId = self.posts.last?.id
            self.postsListLoadIsInProgress = false
        }
    }

    private static let postsChunkLimit = 15
    private var posts = [Post]()
    private var currentLastPostId: String? = nil
    private var postsListLoadIsInProgress = false
}

struct PostDisplayItem {
    static let defaultImagePlaceholderName = "image-placeholder"
    let author: String
    let time: String
    let title: String
    let commentsCountText: String
    let image: UIImage?
    
    init(post: Post) {
        author = post.author
        if let diffInHours = Calendar.current.dateComponents([.hour], from: post.dateCreated, to: Date()).hour {
            let concatenation = diffInHours > 1 ? "hours" : "hour"
            time = "\(diffInHours) \(concatenation) ago"
        } else {
            time = "? hours ago"
        }
        title = post.title
        commentsCountText = "Comments: \(post.commentsCount)"
        image = UIImage(named: PostDisplayItem.defaultImagePlaceholderName) // TODO
    }
}
