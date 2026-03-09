//
//   LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 11/02/26.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    /// 1: test to check we don't store  the cache upon FeedStore creation(context- load cache)
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    /// 2: when we load we request cache retrieval
    /// receivedMessage should have .retrive message type when we invoke load() from sut(LocalFeedLoader)
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        sut.load{ _ in }
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    /// 3. when we request cache retrieval, for ex- Error course(sad path) - system delivers error
    /// load() needs to receive a error in a completion closure arg
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        expect(sut, toCompleteFrom: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    /// 4. empty image case - [FeedItem] is [] when load() called
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        expect(sut, toCompleteFrom: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    /// 8: when cache is retrieved and its gives error
    func test_load_HasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    /// 9: on load() when we get .success(emptyCache)- query only
    func test_load_HasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    /// 10: on load() when our cacheAge less than maxCacheAge - has no sideEffect
    func test_load_HasNoSideEffectsOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    /// 11: on load() when our cacheAge equal to maxCacheAge days- has no side-eefect
    func test_load_HasNoSideEffectOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    /// 12: on load() when our cacheAge more than maxCacheAge-has no side-eefect
    func test_load_hasNoSideEffectOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -2)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_doesNotDeliverAfterSUTHaveBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults =  [LocalFeedLoader.LoadResult]()
        sut?.load { result in
            receivedResults.append(result)
        }

        /// deallocate sut
        sut = nil
        store.completeRetrievalWithEmptyCache()
        XCTAssertTrue(receivedResults.isEmpty)
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
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteFrom expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedImages), .success( expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
}
