//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Aritra on 01/03/26.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {

    public init() {
        
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
    public func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        
        completion(.empty)
    }
}
