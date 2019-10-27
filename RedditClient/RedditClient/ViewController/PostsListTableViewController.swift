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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadPostsListData()
    }
    
    private func reloadPostsListData() {
        viewModel.getTopPosts()
    }
    
    private func subscribeToViewModel() {
        viewModel.postsListChanged = { [weak self] posts in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        viewModel.postChangedAtIndex = { [weak self] index in
            DispatchQueue.main.async {
                let updatedIndexPath = IndexPath(row: index, section: 0)
                if self?.tableView.indexPathsForVisibleRows?.contains(updatedIndexPath) == true {
                    self?.tableView.reloadRows(at: [updatedIndexPath], with: .none)
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.postsDisplayItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseIdentifier, for: indexPath) as! PostTableViewCell
        let currentPost = viewModel.postsDisplayItems[indexPath.row]
        cell.authorLabel.text = currentPost.author
        cell.timeLabel.text = currentPost.time
        cell.titleLabel.text = currentPost.title
        cell.commentsLabel.text = currentPost.commentsCountText
        cell.thumbnailImageView.image = viewModel.getPostThumbnail(currentPost.id)
        return cell
    }
    
}

extension PostsListTableViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if indexPaths.last?.row == viewModel.postsDisplayItems.count - 1 {
            viewModel.getTopPosts()
        }
    }
    
}
