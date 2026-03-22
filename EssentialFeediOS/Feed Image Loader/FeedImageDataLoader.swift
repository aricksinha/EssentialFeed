//
//  FeedImageDataLoader.swift
//  EssentialFeediOS
//
//  Created by Aritra on 22/03/26.
//

import Foundation

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    typealias Result = Swift.Result< Data, Error>
    func loadImageData(
        from url: URL,
        completion: @escaping (Result) -> Void
    ) -> FeedImageDataLoaderTask
}
