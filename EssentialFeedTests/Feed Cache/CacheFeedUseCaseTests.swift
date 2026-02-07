//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 07/02/26.
//

import XCTest
import EssentialFeed

final class FeedStore {
   var  deleteFeedCacheCallCount = 0
    
    func deleteCachedFeed() {
        deleteFeedCacheCallCount += 1
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed()
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    /// 1: test to check we don't delete the cache upon FeedStore creation
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteFeedCacheCallCount, 0)
    }
    
    /// 2: test the save command - then request cache deletion
    func test_save_requestCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        sut.save(items)
        XCTAssertEqual(store.deleteFeedCacheCallCount, 1)
    }
    
    //MARK: - Helper
    private func uniqueFeedItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}
