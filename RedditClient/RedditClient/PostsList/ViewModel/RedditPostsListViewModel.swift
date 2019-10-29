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
    var postsListAdded: (([PostDisplayItem], [Int]) -> ())? { get set }
    var postChangedAtIndex: ((Int) -> ())? { get set }
    var postsDisplayItems: [PostDisplayItem] { get }

    init(apiClient: APIClient, imageDownloader: ImageDownloader)
    func getTopPosts()
    func getPostThumbnail(_ postId: String) -> UIImage?
    func fullImageViewModel(_ postId: String) -> FullImageViewModel?
}

class RedditPostsListViewModel : PostsListViewModel {
    let apiClient: APIClient
    let imageDownloader: ImageDownloader
    var postsListAdded: (([PostDisplayItem], [Int]) -> ())? = nil
    var postChangedAtIndex: ((Int) -> ())? = nil
    private(set) var postsDisplayItems = [PostDisplayItem]()

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
            // Calculate indexes for new posts
            let startIndex = self.posts.count
            let endIndex = startIndex + recentPosts.count - 1
            let addedIndexes = Array((startIndex...endIndex))
            self.posts = self.posts + recentPosts
            self.postsDisplayItems = self.postsDisplayItems + recentPosts.map{ PostDisplayItem(post: $0) }
            self.currentLastPostId = self.posts.last?.id
            self.postsListLoadIsInProgress = false
            self.postsListAdded?(self.postsDisplayItems, addedIndexes)
        }
    }
    
    func getPostThumbnail(_ postId: String) -> UIImage? {
        guard let thumbnailURL = postIdtoThumbnailURLMap[postId] else {
            return UIImage(named: RedditPostsListViewModel.defaultImageName)
        }
        guard let cachedImage = imageDownloader.cachedImage(url: thumbnailURL!) else {
            imageDownloader.downloadImage(url: thumbnailURL!) { [weak self] image, url in
                if let index = self?.thumbnailURLtoIndexMap[url] {
                    self?.postChangedAtIndex?(index)
                }
            }
            return UIImage(named: RedditPostsListViewModel.defaultImageName)
        }
        return cachedImage
    }
    
    func fullImageViewModel(_ postId: String) -> FullImageViewModel? {
        guard let fullImageURL = postIdtoFullImageURLMap[postId] else {
            return nil
        }
        return RedditFullImageViewModel(imageURL: fullImageURL!, imageDownloader: RedditImageDownloader(urlCache: URLCache.shared))
    }

    private static let postsChunkLimit = 15
    private static let defaultImageName = "image-placeholder"
    
    private var posts = [Post]()
    private var currentLastPostId: String? = nil
    private var postsListLoadIsInProgress = false
    private var postIdtoThumbnailURLMap = [String : URL?]()
    private var postIdtoFullImageURLMap = [String : URL?]()
    private var thumbnailURLtoIndexMap = [URL : Int]()

    // Calculate and prepare some cached values for a better performance
    private func processChunk(_ recentPosts: [Post]) {
        for (idx, post) in recentPosts.enumerated() {
            self.postIdtoThumbnailURLMap[post.id] = post.thumbnailURL
            self.postIdtoFullImageURLMap[post.id] = post.fullImageURL
            if let thumbnailURL = post.thumbnailURL {
                self.thumbnailURLtoIndexMap[thumbnailURL] = posts.count + idx
            }
        }
    }
}

struct PostDisplayItem {
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
