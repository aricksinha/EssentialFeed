//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 20/02/26.
//

import XCTest
import EssentialFeed

//MARK: -  Prod code
class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        /// Decode the cache model  & then retrieve the feed and timestamp
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
        
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        do {
            /// hit the disk
            let encoder = JSONEncoder()
            let encoded = try! encoder.encode(
                Cache(feed: feed.map{ CodableFeedImage(image: $0) },
                      timestamp: timestamp)
            )
            /// write the content to disk placed at storeURL - this url represents allocation in disk(it can be pvt detail)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

//MARK: -  Test code
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
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        let insertionError = insert((feed.local, timestamp), to: sut)
        XCTAssertNotNil(insertionError)
    }
    
    //MARK: - Helpers
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
       let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
       trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
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
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
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
