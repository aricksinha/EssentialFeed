//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Aritra on 01/03/26.
//

import CoreData
import Foundation

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(
            modelName: "FeedStore",
            url: storeURL,
            bundle: bundle
        )
        /// Add private background context to perform store operations
        context = container.newBackgroundContext()
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            completion(Result {
                /// find a cache context and if we find it - we delete it then we save the operation
                try ManagedCache.find(context: context).map(context.delete).map(context.save)
            })
        }
    }
    
    public func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            completion(Result {
                /// Get unique instance for the cache in the context
                let managedCache = try ManagedCache.newUniqueInstances(context: context)
                // set the timestamp & feed
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, context: context)

                /// save()
                try context.save()
            })
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion)  {
        perform { context in
            completion(Result{
                // Fetch Feeds from Coredata cache - defined a cache in the context(ManagedCache)
                try ManagedCache.find(context: context).map {
                    /// Convert cache.feed[NSOrderedSet] into ManagedFeedImage and ManagedFeedImage into LocalFeedImage
                    return CachedFeed(feed: $0.localFeeds,
                                      timestamp: $0.timestamp)
                }
            })
        }
    }
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform{ action(context) }
    }
}
