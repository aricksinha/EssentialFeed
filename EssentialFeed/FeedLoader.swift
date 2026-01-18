//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 17/01/26.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}
protocol FeedLoader {
    // need to think about what will return happy/sad path
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
