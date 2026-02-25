//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 20/02/26.
//

import XCTest
import EssentialFeed

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache()
    func test_retrieve_HasNoSideEffectOnEmptyCache()
    func test_retrieve_deliversFoundValueOnNonEmptyCache()
    func test_retrieve_HasNoSideEffectOnNonEmptyCache()
    
    
    func test_insert_overridePreviousInsertedValue()
    
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    
    func test_storesSideEffect_runsSerially()
}

/// Interface for error in retrieve()
protocol FailableRetrieveFeedStoreSpecs {
    func test_retrieve_deliverFailureOnRetrievalError()
    func test_retrieve_HasNoSideEffectOnFailure()
}

/// Interface for error in insert()
protocol FailableInsertFeedStoreSpecs {
    func test_insert_deliverOnInsertionError()
    func test_insert_HasNoSideEffectOnInsertionError()
}

/// Interface for error in delete
protocol FailableDeleteFeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_HasNoSideEffectsOnDeletionError()
}
final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        /// clean up disk b4 running tests - prevent side-effects (non-deterministic nature)
        setUpEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        /// clean up disk after running tests - prevent side-effects (non-deterministic nature)
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        /// call retrieve thinking CodableFeedStore : <FeedStore>
        /// func retrieve(completion: @escaping RetrievalCompletion)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_HasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        /// retrieve called twice
        expect(sut, toRetrieve: .empty)
        expect(sut, toRetrieve: .empty)
    }
    
    /// Retrieve- non empty cache return data
    /// Insert - insert into empty cache stores Data
    func test_retrieve_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        /// insert
        insert((feed.local, timestamp), to: sut)
        /// retrieve
        expect(sut, toRetrieve: .found(feed: feed.local, timestamp: timestamp))
    }
    
    /// Retrieve non empty cache twice return same Data
    func test_retrieve_HasNoSideEffectOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
       
        /// insert
        insert((feed.local, timestamp), to: sut)
        /// retrieve twice
        expect(sut, toRetrieve: .found(feed: feed.local, timestamp: timestamp))
        expect(sut, toRetrieve: .found(feed: feed.local, timestamp: timestamp))
    }
    
    ///
    func test_retrieve_deliverFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        /// write wrong data on cache to get retrival error
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_HasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        /// write wrong data on cache to get retrival error
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    /// INSERT
    func test_insert_overridePreviousInsertedValue() {
        let sut = makeSUT()
        
        let firstInsertedError = insert((uniqueImageFeed().local, Date()), to: sut)
        XCTAssertNil(firstInsertedError, "Expected to insert cache successfully")
        
        let latestFeed = uniqueImageFeed().local
        let timestamp = Date()
        let latestInsertionError =  insert((latestFeed, timestamp), to: sut)
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: timestamp))
        
    }
    
    func test_insert_deliverOnInsertionError() {
        let invalidStoreURL = URL(string: "https://invalid.store")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let insertionError = insert((feed, timestamp), to: sut)
        XCTAssertNotNil(insertionError)
    }
    
    func test_insert_HasNoSideEffectOnInsertionError() {
        let invalidStoreURL = URL(string: "https://invalid.store")
        let sut = makeSUT(storeURL: invalidStoreURL)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        expect(sut, toRetrieve: .empty)
    }
    
    // DELETE
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        insert((uniqueImageFeed().local, Date()), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }
    
    func test_delete_HasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    /// if we expect them to run serially then we expect them to finish in order - which they not they will start in order but not finish in order
    func test_storesSideEffect_runsSerially() {
        let sut = makeSUT()
        var completionOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completionOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completionOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completionOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completionOperationsInOrder, [op1, op2, op3])
    }
    
    //MARK: - Helpers
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
       let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
       trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }

    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Waiting For Cache retrieval")
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure):
                break
            case (.found(let expected), .found(let retrieved)):
                XCTAssertEqual(expected.feed, retrieved.feed, file: file, line: line)
                XCTAssertEqual(expected.timestamp, retrieved.timestamp, file: file, line: line)
            default:
                XCTFail("Expected retriving failed")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setUpEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
