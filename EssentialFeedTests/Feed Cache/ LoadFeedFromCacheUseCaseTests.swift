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
        var receivedError: Error?
        let exp = expectation(description: "Wait for completion")
        sut.load { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        store.completeRetrieval(with: retrievalError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, retrievalError)
    }
    
    /// 4. empty image case - [FeedItem] is [] when load() called
//    func test_load_deliversNoImagesOnEmptyCache() {
//        let (sut, store) = makeSUT()
//        let retrievalError = anyNSError()
//        var receivedImages: [FeedImage]?
//        let exp = expectation(description: "Wait for completion")
//        sut.load { result in
//            switch result {
//                
//            }
//            exp.fulfill()
//        }
//        store.completeRetrieval(with: retrievalError)
//        wait(for: [exp], timeout: 1.0)
//        XCTAssertEqual(receivedError as NSError?, retrievalError)
//    }
    
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
