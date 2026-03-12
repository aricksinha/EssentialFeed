//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 17/01/26.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>
    func load(completion: @escaping (Result) -> Void)
}
