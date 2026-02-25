//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 20/02/26.
//

import XCTest
import EssentialFeed

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs

final class CodableFeedStoreTests: XCTestCase, FailableFeedStore  {
    
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
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_HasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        /// retrieve called twice
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    /// Retrieve- non empty cache return data
    /// Insert - insert into empty cache stores Data
    func test_retrieve_deliversFoundValueOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    /// Retrieve non empty cache twice return same Data
    func test_retrieve_HasNoSideEffectOnNonEmptyCache() {
        let sut = makeSUT()
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    ///
    func test_retrieve_deliverFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        /// write wrong data on cache to get retrival error
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    func test_retrieve_HasNoSideEffectOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        /// write wrong data on cache to get retrival error
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    /// INSERT
    func test_insert_overridePreviousInsertedValue() {
        let sut = makeSUT()
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_deliverOnInsertionError() {
        let invalidStoreURL = URL(string: "https://invalid.store")
        let sut = makeSUT(storeURL: invalidStoreURL)
        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_HasNoSideEffectOnInsertionError() {
        let invalidStoreURL = URL(string: "https://invalid.store")
        let sut = makeSUT(storeURL: invalidStoreURL)
       assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    // DELETE
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
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
