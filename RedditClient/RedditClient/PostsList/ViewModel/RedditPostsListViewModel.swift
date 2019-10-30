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
    var postsDisplayItemsCount: Int { get }

    init(apiClient: APIClient, imageDownloader: ImageDownloader)
    func getTopPosts()
    func getPostThumbnail(_ postId: String) -> UIImage?
    func fullImageViewModel(_ postId: String) -> FullImageViewModel?
    func postDiplayItem(atIndex: Int) -> PostDisplayItem?
}

class RedditPostsListViewModel : PostsListViewModel {
    
    let apiClient: APIClient
    let imageDownloader: ImageDownloader
    var postsListAdded: (([PostDisplayItem], [Int]) -> ())? = nil
    var postChangedAtIndex: ((Int) -> ())? = nil
    var postsDisplayItemsCount: Int {
        var result = 0
        syncQueue.sync {
            result = postsDisplayItems.count
        }
        return result
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
            self.syncQueue.async(flags: .barrier) {
                let startIndex = self.posts.count
                let endIndex = startIndex + recentPosts.count - 1
                let addedIndexes = Array(startIndex...endIndex)
                self.processChunk(recentPosts)
                DispatchQueue.main.async {
                    self.postsListAdded?(self.postsDisplayItems, addedIndexes)
                }
            }
        }
    }
    
    func getPostThumbnail(_ postId: String) -> UIImage? {
        guard let thumbnailURL = storedThumbnailURL(postId: postId) else {
            return UIImage(named: RedditPostsListViewModel.defaultImageName)
        }
        
        if let cachedImage = imageDownloader.cachedImage(url: thumbnailURL) {
            return cachedImage
        }
        
        imageDownloader.downloadImage(url: thumbnailURL) { [weak self] image, url in
            if let index = self?.storedIndex(thumbnailURL: url) {
                self?.postChangedAtIndex?(index)
            }
        }
        
        return UIImage(named: RedditPostsListViewModel.defaultImageName)
    }
    
    func fullImageViewModel(_ postId: String) -> FullImageViewModel? {
        guard let fullImageURL = storedFullImageURL(postId: postId) else {
            return nil
        }
        return RedditFullImageViewModel(imageURL: fullImageURL, imageDownloader: RedditImageDownloader(urlCache: URLCache.shared))
    }
    
    func postDiplayItem(atIndex: Int) -> PostDisplayItem? {
        var result: PostDisplayItem? = nil
        syncQueue.sync {
            if atIndex < self.postsDisplayItemsCount {//} postsDisplayItems.count {
                result = postsDisplayItems[atIndex]
            }
        }
        return result
    }

    // MARK: - Private
    private static let postsChunkLimit = 15
    private static let defaultImageName = "image-placeholder"
    
    private var posts = [Post]()
    private var currentLastPostId: String? = nil
    private var postsListLoadIsInProgress = false
    private var postsDisplayItems = [PostDisplayItem]()
    private var postIdtoThumbnailURLMap = [String : URL]()
    private var postIdtoFullImageURLMap = [String : URL]()
    private var thumbnailURLtoIndexMap = [URL : Int]()
    private var syncQueue = DispatchQueue(label: "com.RedditClient.RedditPostsListViewModel.syncQueue", attributes: .concurrent)

    // Calculate and prepare some cached values for a better performance
    private func processChunk(_ recentPosts: [Post]) {
        for (idx, post) in recentPosts.enumerated() {
            if let fullImageURL = post.fullImageURL {
                self.postIdtoFullImageURLMap[post.id] = fullImageURL
            }
            if let thumbnailURL = post.thumbnailURL {
                self.postIdtoThumbnailURLMap[post.id] = thumbnailURL
                self.thumbnailURLtoIndexMap[thumbnailURL] = self.posts.count + idx
            }
        }
        // Calculate indexes for new posts
        self.posts = self.posts + recentPosts
        self.currentLastPostId = self.posts.last?.id
        self.postsDisplayItems = self.postsDisplayItems + recentPosts.map{ PostDisplayItem(post: $0) }
        self.postsListLoadIsInProgress = false
    }
    
    private func storedThumbnailURL(postId: String) -> URL? {
        var result: URL? = nil
        syncQueue.sync {
            result = postIdtoThumbnailURLMap[postId]
        }
        return result
    }

    private func storedFullImageURL(postId: String) -> URL? {
        var result: URL? = nil
        syncQueue.sync {
            result = postIdtoFullImageURLMap[postId]
        }
        return result
    }
    
    private func storedIndex(thumbnailURL: URL) -> Int? {
        var result: Int? = nil
        syncQueue.sync {
            result = thumbnailURLtoIndexMap[thumbnailURL]
        }
        return result
    }
}

struct PostDisplayItem {
    let id: String
    let author: String
    let time: String
    let title: String
    let commentsCountText: String
    let canOpen: Bool

    init(post: Post) {
        author = post.author
        if let diffInHours = Calendar.current.dateComponents([.hour], from: post.dateCreated, to: Date()).hour {
            let timeFormat = diffInHours > 1 ? NSLocalizedString("PostsList.TimeFormatPlural", comment: "") : NSLocalizedString("PostsList.TimeFormatSingular", comment: "")
            time = String.localizedStringWithFormat(timeFormat, diffInHours)
        } else {
            time = NSLocalizedString("PostsList.TimeUnknown", comment: "")
        }
        title = post.title
        let commentsFormat = NSLocalizedString("PostsList.CommentsFormat", comment: "")
        commentsCountText = String.localizedStringWithFormat(commentsFormat, post.commentsCount)
        id = post.id
        canOpen = post.fullImageURL != nil
    }
}
