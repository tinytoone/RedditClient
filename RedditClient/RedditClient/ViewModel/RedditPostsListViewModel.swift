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
    var imageDownloader: ImageDownloader { get }
    var postsListChanged: ([PostDisplayItem]) -> () { get set }
    var postChangedAtIndex: (Int) -> () { get set }
    var postsDisplayItems: [PostDisplayItem] { get }

    init(apiClient: APIClient, imageDownloader: ImageDownloader)
    func getTopPosts()
    func getPostThumbnail(_ postId: String) -> UIImage?
}

class RedditPostsListViewModel : PostsListViewModel {
    let apiClient: APIClient
    let imageDownloader: ImageDownloader
    var postsListChanged: ([PostDisplayItem]) -> () = {_ in}
    var postChangedAtIndex: (Int) -> () = {_ in}
    private(set) var postsDisplayItems = [PostDisplayItem]() {
        didSet {
            postsListChanged(postsDisplayItems)
        }
    }

    required init(apiClient: APIClient, imageDownloader: ImageDownloader) {
        self.apiClient = apiClient
        self.imageDownloader = imageDownloader
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
            self.processChunk(recentPosts)
            self.posts = self.posts + recentPosts
            self.postsDisplayItems = self.posts.map{ PostDisplayItem(post: $0) }
            self.currentLastPostId = self.posts.last?.id
            self.postsListLoadIsInProgress = false
        }
    }
    
    func getPostThumbnail(_ postId: String) -> UIImage? {
        guard let thumbnailURL = postIdtoThumbnailURLMap[postId] else {
            return UIImage(named: PostDisplayItem.defaultImagePlaceholderName)
        }
        guard let cachedImage = imageDownloader.cachedImage(url: thumbnailURL!) else {
            imageDownloader.downloadImage(url: thumbnailURL!) { [weak self] image, url in
                if let index = self?.thumbnailURLtoIndexMap[url] {
                    self?.postChangedAtIndex(index)
                }
            }
            return UIImage(named: PostDisplayItem.defaultImagePlaceholderName)
        }
        return cachedImage
     }

    private static let postsChunkLimit = 15
    private var posts = [Post]()
    private var currentLastPostId: String? = nil
    private var postsListLoadIsInProgress = false
    private var postIdtoThumbnailURLMap = [String : URL?]()
    private var thumbnailURLtoIndexMap = [URL : Int]()

    // Calculate and prepare some cached values for a better performance
    private func processChunk(_ recentPosts: [Post]) {
        for (idx, post) in recentPosts.enumerated() {
            self.postIdtoThumbnailURLMap[post.id] = post.thumbnailURL
            if let thumbnailURL = post.thumbnailURL {
                self.thumbnailURLtoIndexMap[thumbnailURL] = posts.count + idx
            }
        }
    }
}

struct PostDisplayItem {
    static let defaultImagePlaceholderName = "image-placeholder"
    let id: String
    let author: String
    let time: String
    let title: String
    let commentsCountText: String
    
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
        id = post.id
    }
}
