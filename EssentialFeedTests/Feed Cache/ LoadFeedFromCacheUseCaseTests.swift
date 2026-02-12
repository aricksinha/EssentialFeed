//
//   LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 11/02/26.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    /// 1: test to check we don't store  the cache upon FeedStore creation
    func test_init_doesNotMessageStoreUponCreation() {
        let (sut, store) = makeSUT()
        sut.load()
        XCTAssertEqual(store.receivedMessages, [])
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
}
