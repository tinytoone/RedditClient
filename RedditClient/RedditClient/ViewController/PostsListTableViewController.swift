//
//  PostsListTableViewController.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import UIKit

class PostsListTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadPostsListData()
    }
    
    private func reloadPostsListData() {
        refreshControl?.beginRefreshingManually()
        // Do Refresh
        refreshControl?.endRefreshing()
    }
    
    // MARK: - IBActions

    @IBAction func refreshControllValueChangedAction(_ sender: Any) {
        reloadPostsListData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.reuseIdentifier, for: indexPath) as! PostTableViewCell

        return cell
    }

}
