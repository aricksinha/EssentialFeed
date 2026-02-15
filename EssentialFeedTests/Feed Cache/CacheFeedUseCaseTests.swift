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

final class CacheFeedUseCaseTests: XCTestCase {

    /// 1: test to check we don't delete the cache upon FeedStore creation
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    /// 2: test the save command - then request cache deletion
    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        sut.save(uniqueImageFeed().models){ _ in }
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    ///3: if Deleting cache might fail  then, we shdn’t progress with inserting Items in cache
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        sut.save(uniqueImageFeed().models){ _ in }
        store.completeDeletion(with: deletionError)
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    /// 5: timestamp the new cache b4 storing it
    func test_save_requestNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT{ timestamp }
        let (feed, localItems) = uniqueImageFeed()
        sut.save(feed){ _ in }
        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(localItems, timestamp)])
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
    
    /// 9: when we are at process of saving & instance is deallocated- we don't want the completion block to be invoked
    /// here we chose for deletion error coz its one of the path to invoke completion
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        /// optional ref to sut as its to be deallocated later
        var sut: LocalFeedLoader? = LocalFeedLoader(
            store: store,
            currentDate: Date.init
        )
        
        /// Action
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save([uniqueImage()], completion: { result in
            receivedResults.append(result)
        })
        
        /// complete deletion with error after sut deallocated
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        /// receivedResults should be emoty
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        /// optional ref to sut as its to be deallocated later
        var sut: LocalFeedLoader? = LocalFeedLoader(
            store: store,
            currentDate: Date.init
        )
        
        /// Action
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueImageFeed().models, completion: { result in
            receivedResults.append(result)
        })
        
        store.completeDeletionSuccessfully()
        /// complete insertion with error after sut deallocated
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        /// receivedResults should be emoty
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
        toCompleteWithError expectedError: NSError?,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var receivedError: Error?
        let exp = expectation(description: "Wait for save completion")
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }
}
