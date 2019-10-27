//
//  RedditAPIClient.swift
//  RedditClient
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import Foundation

protocol APIClient {
    func performRequest(endpoint: APIEndpoint, completion: @escaping (Data?, APIClientError?) -> ())
}

enum APIClientError : Error {
    case noInternet
    case other
}

class RedditAPIClient: APIClient {
    
    private var uberURLSession: URLSession!
    private var uberURLConfiguration: URLSessionConfiguration!

    init() {
        uberURLConfiguration = .default
        uberURLSession = URLSession(configuration: uberURLConfiguration)
    }
        
    func performRequest(endpoint: APIEndpoint, completion: @escaping (Data?, APIClientError?) -> ()) {
        let dataTask = uberURLSession.dataTask(with: endpoint.url) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse, 200...299 ~= response.statusCode {
                completion(data, nil)
            } else if (error as? URLError)?.code == .notConnectedToInternet {
                completion(nil, .noInternet)
            } else {
                completion(nil, .other)
            }
        }
        dataTask.resume()
    }
}
