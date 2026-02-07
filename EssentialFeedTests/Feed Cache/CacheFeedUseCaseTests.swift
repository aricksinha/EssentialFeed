//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 07/02/26.
//

import XCTest

final class FeedStore {
   var  deleteFeedCacheCallCount = 0
}

class LocalFeedLoader {
    init(store: FeedStore) {
        
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    /// test to check we don't delete the cache upon FeedStore creation
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteFeedCacheCallCount, 0)
    }
}
