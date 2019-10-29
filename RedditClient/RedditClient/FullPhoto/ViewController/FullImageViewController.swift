//
//  FullImageViewController.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/28/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import UIKit

protocol RestorableViewController {
    var continuationActivity: NSUserActivity? { get }
}

class FullImageViewController: UIViewController {
  
    var viewModel: FullImageViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveAction))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToViewModel()
        setupImage(image: viewModel.currentImage)
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.savingToPhotosEnabled
        viewModel.getImage()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Maintaining Orientation Changes to adjust image scale/zoom
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (context) in
            self.setupImage(image: self.imageView.image)
        }
    }
        
    @IBOutlet private weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var loadingView: UIView!
    
    @objc private func saveAction() {
        viewModel.saveCurrentImageToPhotos()
    }
    
    private func subscribeToViewModel() {
        viewModel.loadStatusChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                self?.loadingView.isHidden = !isLoading
            }
        }
        viewModel.currentImageChanged = { [weak self] image in
            DispatchQueue.main.async {
                self?.setupImage(image: image)
            }
        }
        viewModel.savingToPhotosEnabledChanged = { [weak self] enabled in
            DispatchQueue.main.async {
                self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            }
        }
        viewModel.wantsToShowUserImportantMessage = { [weak self] title, message in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func setupImage(image: UIImage?) {
        imageView.image = image
        view.layoutIfNeeded()
        setupScaling()
        performImageCentering()
        imageView.isHidden = false
    }
    
    private func setupScaling() {
        let widthScaling = view.bounds.size.width / imageView.bounds.width
        let heightScaling = view.bounds.height / imageView.bounds.height
        let minScaling = min(widthScaling, heightScaling)
        scrollView.minimumZoomScale = minScaling
        scrollView.maximumZoomScale = 1/minScaling
        scrollView.zoomScale = scrollView.minimumZoomScale
    }
    
    private func performImageCentering() {
        let verticalOffset = max(0, (view.bounds.size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = verticalOffset
        imageViewBottomConstraint.constant = verticalOffset

        let horizontalOffset = max(0, (view.bounds.size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = horizontalOffset
        imageViewTrailingConstraint.constant = horizontalOffset

        view.layoutIfNeeded()
    }
        
}

extension FullImageViewController: UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        performImageCentering()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
  
}

extension FullImageViewController: RestorableViewController {
    
    var continuationActivity: NSUserActivity? {
        let activity = NSUserActivity(activityType: Constants.StateRestoration.FullImageRestorationType)
        activity.persistentIdentifier = Constants.StateRestoration.FullImageRestorationType
        activity.addUserInfoEntries(from: viewModel.continuationActivityParameters())
        return activity
    }

}
