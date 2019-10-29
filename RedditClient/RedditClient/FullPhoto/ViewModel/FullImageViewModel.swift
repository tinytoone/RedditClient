//
//  FullImageViewModel.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/28/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation
import UIKit.UIImage

protocol FullImageViewModel {
    var imageDownloader: ImageDownloader { get }
    var loadStatusChanged: (Bool) -> () { get set }
    var imageUpdated: (UIImage) -> () { get set }
    
    init(imageURL: URL, imageDownloader: ImageDownloader)
    func getImage()
}

class RedditFullImageViewModel: FullImageViewModel {
    let imageDownloader: ImageDownloader
    var loadStatusChanged: (Bool) -> () = { _ in }
    var imageUpdated: (UIImage) -> () = { _ in }
    
    required init(imageURL: URL, imageDownloader: ImageDownloader) {
        self.imageURL = imageURL
        self.imageDownloader = imageDownloader
    }
    
    func getImage() {
        guard let cachedImage = imageDownloader.cachedImage(url: imageURL) else {
            loadStatusChanged(true)
            imageDownloader.downloadImage(url: imageURL) { [weak self] image, url in
                let imageToReturn = image ?? UIImage(named: RedditFullImageViewModel.defaultImageName)!
                self?.imageUpdated(imageToReturn)
                self?.loadStatusChanged(false)
            }
            return
        }
        self.imageUpdated(cachedImage)
    }
    
    private static let defaultImageName = "image-placeholder-full"
    private let imageURL: URL

}
