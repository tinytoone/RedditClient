//
//  FullImageViewModel.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/28/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation
import UIKit.UIImage

protocol RestorableViewModel {
    static func restoreFrom(userActivity: NSUserActivity) -> RestorableViewModel?
    func continuationActivityParameters() -> [AnyHashable: Any]
}

protocol FullImageViewModel: RestorableViewModel {
    var imageDownloader: ImageDownloader { get }
    var wantsToShowUserImportantMessage: ((String, String) -> ())? { get set }
    var loadStatusChanged: ((Bool) -> ())? { get set }
    var savingToPhotosEnabledChanged: ((Bool) -> ())? { get set }
    var currentImageChanged: ((UIImage) -> ())? { get set }
    var currentImage: UIImage? { get }
    var savingToPhotosEnabled: Bool { get }

    init(imageURL: URL, imageDownloader: ImageDownloader)
    func getImage()
    func saveCurrentImageToPhotos()
}

class RedditFullImageViewModel: NSObject, FullImageViewModel {

    let imageDownloader: ImageDownloader
    var wantsToShowUserImportantMessage: ((String, String) -> ())? = nil
    var loadStatusChanged: ((Bool) -> ())? = nil
    var savingToPhotosEnabledChanged: ((Bool) -> ())? = nil
    var currentImageChanged: ((UIImage) -> ())? = nil
    private(set) var currentImage: UIImage? = nil {
        didSet {
            guard let currentImage = currentImage else {
                return
            }
            currentImageChanged?(currentImage)
        }
    }
    private(set) var savingToPhotosEnabled = false {
        didSet {
            savingToPhotosEnabledChanged?(savingToPhotosEnabled)
        }
    }

    required init(imageURL: URL, imageDownloader: ImageDownloader) {
        self.imageURL = imageURL
        self.imageDownloader = imageDownloader
    }
    
    func getImage() {
        guard let cachedImage = imageDownloader.cachedImage(url: imageURL) else {
            loadStatusChanged?(true)
            imageDownloader.downloadImage(url: imageURL) { [weak self] imageFromRemote, url in
                let newImage = imageFromRemote ?? UIImage(named: RedditFullImageViewModel.defaultImageName)!
                self?.currentImage = newImage
                self?.currentImageChanged?(newImage)
                self?.savingToPhotosEnabled = imageFromRemote != nil
                self?.loadStatusChanged?(false)
            }
            return
        }
        currentImage = cachedImage
        savingToPhotosEnabled = true
    }
    
    func saveCurrentImageToPhotos() {
        guard savingToPhotosEnabled, let currentImage = self.currentImage else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(currentImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    // MARK: - Restorable View Model
    static func restoreFrom(userActivity: NSUserActivity) -> RestorableViewModel? {
        guard let imageURL = userActivity.userInfo?[RedditFullImageViewModel.imageURLRestoratioKey] as? URL else {
            return nil
        }
        return RedditFullImageViewModel(imageURL: imageURL, imageDownloader: RedditImageDownloader())
    }

    func continuationActivityParameters() -> [AnyHashable: Any] {
        return [RedditFullImageViewModel.imageURLRestoratioKey : imageURL]
    }

    // MARK: - Private
    private static let defaultImageName = "image-placeholder-full"
    private static let imageURLRestoratioKey = "imageURL"
    private let imageURL: URL

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        let title = (error == nil) ? NSLocalizedString("General.Success", comment: "") : NSLocalizedString("General.Error", comment: "")
        let message = (error == nil) ? NSLocalizedString("FullImage.SuccessAlertMessage", comment: "") : NSLocalizedString("FullImage.ErrorAlertMessage", comment: "")
        wantsToShowUserImportantMessage?(title, message)
    }
}
