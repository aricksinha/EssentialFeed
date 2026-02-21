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
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        /// hit the disk
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(
            Cache(feed: feed.map{ CodableFeedImage(image: $0) },
                  timestamp: timestamp)
        )
        /// write the content to disk placed at storeURL - this url represents allocation in disk(it can be pvt detail)
        try! encoded.write(to: storeURL)
        completion(nil)
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
        let exp = expectation(description: "Waiting For Cache retrieval")
        /// call retrieve thinking CodableFeedStore : <FeedStore>
        /// func retrieve(completion: @escaping RetrievalCompletion)
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_HasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Waiting For Cache retrieval")
        /// retrieve called twice
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retriving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    /// Retrieve- non empty cache return data
    /// Insert - insert into empty cache stores Data
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        let exp = expectation(description: "Waiting For Cache retrieval")
        /// insert first
        sut.insert(feed.local, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected Feed to be inserted successfully")
            /// then retrieve
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case .found(let retrievedFeed, let retrievedTimestamp):
                    XCTAssertEqual(retrievedFeed, feed.local)
                    XCTAssertEqual(retrievedTimestamp, timestamp)
                default:
                    XCTFail("Expected found result with feed : \(feed) and timestamp: \(timestamp) got \(retrieveResult) instead")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helpers
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
       let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
       trackForMemoryLeak(sut, file: file, line: line)
        return sut
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
