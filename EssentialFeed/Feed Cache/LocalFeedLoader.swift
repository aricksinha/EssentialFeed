//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 08/02/26.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                /// this block says there is an error
                completion(cacheDeletionError)
            } else {
                /// there is no error so complete insertion
                self.cache(items, with: completion)
            }
        }
    }
    
    private func cache(
        _ items: [FeedItem],
        with completion: @escaping (SaveResult) -> Void
    ) {
        store.insert(items, timestamp: self.currentDate(), completion: { [weak self] error in
                /// if LocalFeedLoader is deallocated - don't let the code block to execute anymore
                guard self != nil else { return }
                completion(error)
            }
        )
    }
}
