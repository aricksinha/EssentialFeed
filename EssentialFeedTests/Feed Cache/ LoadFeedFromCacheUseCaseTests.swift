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
    
    //MARK: - Spy
    final class FeedStoreSpy: FeedStore {
        var deletionCompletions = [DeletionCompletion]()
        var insertionCompletions = [InsertionCompletion]()
        enum ReceivedMessage: Equatable {
          case deleteCachedFeed
          case insert([LocalFeedImage], Date)
        }
        
        private(set) var receivedMessages = [ReceivedMessage]()
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }
        
        func completeDeletion(with error: Error, index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeInsertion(with error: Error, index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func insert(
            _ feed: [LocalFeedImage],
            timestamp: Date,
            completion: @escaping InsertionCompletion
        ) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(feed, timestamp))
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
    
}
