//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Aritra on 11/02/26.
//

import Foundation
import EssentialFeed

final class FeedStoreSpy: FeedStore {
    var deletionCompletions = [DeletionCompletion]()
    var insertionCompletions = [InsertionCompletion]()
    var retrievalCompletions = [RetrievalCompletion]()
    enum ReceivedMessage: Equatable {
      case deleteCachedFeed
      case insert([LocalFeedImage], Date)
      case retrieve
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    //MARK: - Cache Feed UseCase
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
        _ feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping InsertionCompletion
    ) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    //MARK: - Load Feed From Cache UseCase
    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetrieval(with error: Error, index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrievalWithEmptyCache(index: Int = 0) {
        retrievalCompletions[index](.success(.none))
    }

    func completeRetrieval(with feedLocals: [LocalFeedImage], timestamp: Date, index: Int = 0) {
        retrievalCompletions[index](.success(CachedFeed(feed: feedLocals, timestamp: timestamp)))
    }
}
