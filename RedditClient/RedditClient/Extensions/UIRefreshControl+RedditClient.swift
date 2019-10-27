//
//  File.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation
import UIKit

extension UIRefreshControl {
  func beginRefreshingManually() {
    if let scrollView = superview as? UIScrollView {
      scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height), animated: true)
    }
    beginRefreshing()
  }
}
