//
//  String+RedditClient.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/29/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation

extension String {
    func removingXMLPercentEncoding() -> String {
        return self.replacingOccurrences(of: "&amp;", with: "&", options: .literal, range: nil)
    }
}
