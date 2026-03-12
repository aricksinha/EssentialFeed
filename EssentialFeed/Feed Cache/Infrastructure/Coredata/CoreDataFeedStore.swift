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
            do {
                /// find a cache context and if we find it - we delete it then we save the operation
                try ManagedCache.find(context: context).map(context.delete).map(context.save)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                /// Get unique instance for the cache in the context
                let managedCache = try ManagedCache.newUniqueInstances(context: context)
                // set the timestamp & feed
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, context: context)
                
                /// save()
                try context.save()
                // nil passed coz no error is there
                completion(nil)
            } catch {
                completion(error)
            }
            
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion)  {
        perform { context in
            do {
                // Fetch Feeds from Coredata cache - defined a cache in the context(ManagedCache)
                if let cache = try ManagedCache.find(context: context) {
                    /// Convert cache.feed[NSOrderedSet] into ManagedFeedImage and ManagedFeedImage into LocalFeedImage
                    completion(
                        .success(.found(feed: cache.localFeeds,
                                        timestamp: cache.timestamp))
                        
                    )
                } else {
                    /// if can't find the cache
                    completion(.success(.empty))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform{ action(context) }
    }
}
