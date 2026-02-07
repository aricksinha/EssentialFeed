//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 07/02/26.
//

import XCTest
import EssentialFeed

final class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    var deletionCompletions = [DeletionCompletion]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        insertions.append((items, timestamp))
    }
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    /// 1: test to check we don't delete the cache upon FeedStore creation
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deletionCompletions.count, 0)
    }
    
    /// 2: test the save command - then request cache deletion
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        sut.save(items)
        XCTAssertEqual(store.deletionCompletions.count, 1)
    }
    
    ///3: if Deleting cache might fail  then, we shdn’t progress with inserting Items in cache
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let deletionError = anyNSError()
        sut.save(items)
        store.completeDeletion(with: deletionError)
        XCTAssertEqual(store.insertions.count, 0)
    }
    
    /// 4: what shd happen when deletion is successful? - Insert new items in the cache
    func test_save_requestNewCacheInsertionOnSuccessfulDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        sut.save(items)
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.insertions.count, 1)
    }
    
    /// 5: timestamp the new cache b4 storing it
    func test_save_requestNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT{ timestamp }
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        sut.save(items)
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }
    
    //MARK: - Helper
    private func makeSUT(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (sut:LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(store, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueFeedItem() -> FeedItem {
        return FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any-error", code: 0)
    }
}
