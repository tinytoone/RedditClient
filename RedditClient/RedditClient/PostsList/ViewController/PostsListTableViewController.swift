//
//  PostsListTableViewController.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import UIKit

class PostsListTableViewController: UITableViewController {

    var viewModel: PostsListViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
        subscribeToViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadPostsListData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Maintaining Orientation Changes to adjust the scrolling position
        super.viewWillTransition(to: size, with: coordinator)
        self.topVisibleRowBeforeOrientationChangeIndexPath = tableView.indexPathsForVisibleRows?.first
        coordinator.animate(alongsideTransition: nil) { (context) in
            if let indexPath = self.topVisibleRowBeforeOrientationChangeIndexPath {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                self.topVisibleRowBeforeOrientationChangeIndexPath = nil
            }
        }
    }
    
    private var topVisibleRowBeforeOrientationChangeIndexPath: IndexPath?
    
    private func reloadPostsListData() {
        viewModel.getTopPosts()
    }
    
    private func subscribeToViewModel() {
        viewModel.postsListAdded = { [weak self] posts, indexes in
            DispatchQueue.main.async {
                let indexPaths = indexes.map { IndexPath(row: $0, section: 0) }
                self?.tableView.insertRows(at: indexPaths, with: .fade)
            }
        }
        viewModel.postChangedAtIndex = { [weak self] index in
            DispatchQueue.main.async {
                let updatedIndexPath = IndexPath(row: index, section: 0)
                if self?.tableView.indexPathsForVisibleRows?.contains(updatedIndexPath) == true {
                    self?.tableView.reloadRows(at: [updatedIndexPath], with: .fade)
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Posts count + loading cell
        return viewModel.postsDisplayItemsCount + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if indexPath.row == viewModel.postsDisplayItemsCount {
            cell = loadingCell(indexPath: indexPath)
        } else {
            cell = postCell(indexPath: indexPath)
        }
        
        return cell
    }
    
    func loadingCell(indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: Constants.StoryboardId.LoadCell, for: indexPath)
    }
    
    func postCell(indexPath: IndexPath) -> PostTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseIdentifier, for: indexPath) as! PostTableViewCell
        if let currentPost = viewModel.postDiplayItem(atIndex: indexPath.row) {
            cell.authorLabel.text = currentPost.author
            cell.timeLabel.text = currentPost.time
            cell.titleLabel.text = currentPost.title
            cell.commentsLabel.text = currentPost.commentsCountText
            cell.accessoryType = currentPost.canOpen ? .disclosureIndicator : .none
            cell.thumbnailImageView.image = viewModel.getPostThumbnail(currentPost.id)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.row
        guard viewModel.postsDisplayItemsCount > index, let postDisplayItem = viewModel.postDiplayItem(atIndex: index), let fullImageViewModel = viewModel.fullImageViewModel(postDisplayItem.id) else {
            return
        }
        let fullImageViewController = UIStoryboard(name: Constants.StoryboardId.FullImage, bundle: Bundle.main).instantiateInitialViewController() as! FullImageViewController
        fullImageViewController.viewModel = fullImageViewModel
        navigationController?.pushViewController(fullImageViewController, animated: true)
    }
    
}

extension PostsListTableViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.last?.row == viewModel.postsDisplayItemsCount {
            viewModel.getTopPosts()
        }
    }
    
}
