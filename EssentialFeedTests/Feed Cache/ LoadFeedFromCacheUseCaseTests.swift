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

    /// 5: cache expiry error case(system validates the cache less than 7 days old) - system deletes cache + delivers no feed images
    /// lets test happy path for this scenario
    func test_load_deliversCacheImagesOnLessThanSevenDaysOldCache() {
        let (feedModels, feedLocals) = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut, toCompleteFrom: .success(feedModels)) {
            store.completeRetrieval(with: feedLocals, timestamp: lessThanSevenDaysOld)
        }
    }
    
    /// 6: when cache is 7 days old: system deletes cache + delivers no feed images
    func test_load_deliversCacheNoImagesOnSevenDaysOldCache() {
        let (_, feedLocals) = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut, toCompleteFrom: .success([])) {
            store.completeRetrieval(with: feedLocals, timestamp: sevenDaysOldTimestamp)
        }
    }
    
    /// 7: when cache is more than 7 days old
    func test_load_deliversCacheNoImagesOnMoreThanSevenDaysOldCache() {
        let (_, feedLocals) = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThansevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -2)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        expect(sut, toCompleteFrom: .success([])) {
            store.completeRetrieval(with: feedLocals, timestamp: moreThansevenDaysOldTimestamp)
        }
    }
    
    /// 8: when cache is retrieved and its gives error then delete cache
    func test_load_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    /// 9: on load() when we get .success(emptyCache), don't delete cache
    func test_load_doesNotDeletesCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    /// 10: on load() when our cacheAge less than 7 days- don't delete cache
    func test_load_doesNotDeletesCacheOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOld = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: feed.local, timestamp: lessThanSevenDaysOld)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    /// 11: on load() when our cacheAge equal to 7 days-shd delete cache
    func test_load_deletesCacheOnEqualToSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldCache = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: feed.local, timestamp: sevenDaysOldCache)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }

    /// 12: on load() when our cacheAge equal to 7 days-shd delete cache
    func test_load_deletesCacheOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldCache = fixedCurrentDate.adding(days: -7).adding(days: -2)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        /// here we don't care abt result from load
        sut.load { _ in }
        /// we care what happened to store
        store.completeRetrieval(with: feed.local, timestamp: moreThanSevenDaysOldCache)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
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
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any-error", code: 0)
    }

    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }

    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let locals = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models, locals)
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
