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
                /// Inserting to feed cache
                let managedCache = try ManagedCache.newUniqueInstances(context: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, context: context)
                
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
                // Fetch Feeds from Coredata cache
                if let cache = try ManagedCache.find(context: context) {
                    /// Convert cache.feed[NSOrderedSet] into ManagedFeedImage and ManagedFeedImage into LocalFeedImage
                    completion(
                        .found(feed: cache.localFeeds,
                               timestamp: cache.timestamp)
                    )
                } else {
                    completion(.empty)
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

// COREDATA IMPL- INFRA IMPLEMENTATION
@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeeds: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }
    
    static func find(context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    static func newUniqueInstances(context: NSManagedObjectContext) throws -> ManagedCache {
        try find(context: context).map(context.delete)
        return ManagedCache(context: context)
    }
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
    var local: LocalFeedImage {
        return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
    }
    
    /// From [LocalFeedImage] to NSOrderedSet
    static func images(from localFeed: [LocalFeedImage], context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map{ localFeed in
            let managedFeedImage = ManagedFeedImage(context: context)
             managedFeedImage.id = localFeed.id
             managedFeedImage.imageDescription = localFeed.description
             managedFeedImage.location = localFeed.location
             managedFeedImage.url = localFeed.url
             return managedFeedImage
        })
    }
}
