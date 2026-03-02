//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Aritra on 25/02/26.
//

import Foundation

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache()
    func test_retrieve_HasNoSideEffectOnEmptyCache()
    func test_retrieve_deliversFoundValueOnNonEmptyCache()
    func test_retrieve_HasNoSideEffectOnNonEmptyCache()
    
    
    func test_insert_deliversNoErrorOnEmptyCache()
    func test_insert_deliversNoErrorOnNonEmptyCache()
    func test_insert_overridesPreviouslyInsertedCacheValues()
    
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    
    func test_storesSideEffect_runsSerially()
}

/// Interface for error in retrieve()
protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliverFailureOnRetrievalError()
    func test_retrieve_HasNoSideEffectOnFailure()
}

/// Interface for error in insert()
protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliverOnInsertionError()
    func test_insert_HasNoSideEffectOnInsertionError()
}

/// Interface for error in delete
protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_HasNoSideEffectsOnDeletionError()
}
