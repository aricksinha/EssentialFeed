//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 07/02/26.
//

import XCTest
import EssentialFeed

enum Result {
    case success
    case failure(Error)
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [FeedItem], timestamp: Date,completion: @escaping InsertionCompletion
    )
}

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(
                    items,
                    timestamp: self.currentDate(),
                    completion: completion
                )
            } else {
                /// when u don't have error - we need to store / insert items
                completion(error)
            }
        }
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

    /// 1: test to check we don't delete the cache upon FeedStore creation
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    /// 2: test the save command - then request cache deletion
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        sut.save(items){ _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    ///3: if Deleting cache might fail  then, we shdn’t progress with inserting Items in cache
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let deletionError = anyNSError()
        sut.save(items){ _ in }
        store.completeDeletion(with: deletionError)
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    /// 5: timestamp the new cache b4 storing it
    func test_save_requestNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT{ timestamp }
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        sut.save(items){ _ in }
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    /// 6: What shd save() do on Deletion error? - just deliver an error, error occurred operations stopped & since those operations are sync we can also pass a block in save() where we can receive error
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    /// 7: What happens when cache fails to insert items -acc to use-case we need to deliver error
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    /// 8: when everything works successfully - Deletion succeeded + insertion success , Deliver success message
    func test_save_succeedOnSuccessfulDeletionAndInsertion() {
        let (sut, store) = makeSUT()
        expect(sut, toCompleteWithError: nil) {
            /// first deletion needed
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
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
        toCompleteWithError expectedError: NSError?,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var receivedError: Error?
        let exp = expectation(description: "Wait for save completion")
        sut.save([uniqueFeedItem()]) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
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
    
    //MARK: - Spy
    final class FeedStoreSpy: FeedStore {
        var deletionCompletions = [DeletionCompletion]()
        var insertionCompletions = [InsertionCompletion]()
        enum ReceivedMessage: Equatable {
          case deleteCachedFeed
          case insert([FeedItem], Date)
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
            _ items: [FeedItem],
            timestamp: Date,
            completion: @escaping InsertionCompletion
        ) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
