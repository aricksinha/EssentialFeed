//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 14/02/26.
//

import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    /// lets use localFeedLoader - centralize comp to deal cache
    
    /// 1: test to check we don't store  the cache upon FeedStore creation(context - validating cache)
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    /// 2: on validate cache - it should call retrieve and then delete cache on getting error
    func test_validateCache_deleteCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        /// we care what happened to store
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    /// 3: on validate cache - it shd call retrive empty cache then donot delete cache
    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        /// we care what happened to store
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    //MARK: - Helper
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut:LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any-error", code: 0)
    }
}
