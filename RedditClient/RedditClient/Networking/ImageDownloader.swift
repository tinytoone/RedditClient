//
//  ImageDownloader.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation
import UIKit.UIImage

protocol ImageDownloader {
    var urlCache: URLCache { get }
    
    init(urlCache: URLCache)
    func cachedImage(url: URL) -> UIImage?
    func downloadImage(url: URL, completion: @escaping (UIImage?, URL) -> ())
}

class RedditImageDownloader: ImageDownloader {
    
    private(set) var urlCache: URLCache
    
    required init(urlCache: URLCache) {
        self.urlCache = urlCache
        imageDownloaderURLConfiguration = .default
        imageDownloaderURLSession = URLSession(configuration: imageDownloaderURLConfiguration)
    }
        
    func cachedImage(url: URL) -> UIImage? {
        let request = URLRequest(url: url)
        if let data = urlCache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    func downloadImage(url: URL, completion: @escaping (UIImage?, URL) -> ()) {
        let downloadRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.returnCacheDataElseLoad, timeoutInterval: 10)
        let downloadTask = URLSession.shared.downloadTask(with: downloadRequest, completionHandler: { taskUrl, response, error in
            if let taskUrl = taskUrl, let data = try? Data(contentsOf: taskUrl), response != nil && URLCache.shared.cachedResponse(for: downloadRequest) == nil {
                URLCache.shared.storeCachedResponse(CachedURLResponse(response: response!, data: data), for: downloadRequest)
                completion(UIImage(data: data), url)
            }
        })
        downloadTask.resume()
    }
    
    private var imageDownloaderURLSession: URLSession!
    private var imageDownloaderURLConfiguration: URLSessionConfiguration!

}
