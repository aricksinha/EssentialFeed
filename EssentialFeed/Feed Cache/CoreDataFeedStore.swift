//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Aritra on 01/03/26.
//

import CoreData

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
        
    }
    
    public func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            do {
                /// Inserting to feed cache
                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timestamp
                managedCache.feed = NSOrderedSet(array: feed.map{ localFeed in
                   let managedFeedImage = ManagedFeedImage(context: context)
                    managedFeedImage.id = localFeed.id
                    managedFeedImage.imageDescription = localFeed.description
                    managedFeedImage.location = localFeed.location
                    managedFeedImage.url = localFeed.url
                    return managedFeedImage
                })
                
                try context.save()
                // nil passed coz no error is there
                completion(nil)
            } catch {
                completion(error)
            }
            
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion)  {
        let context = self.context
        context.perform {
            do {
                // Fetch Feeds from Coredata cache
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false
                if let cache = try context.fetch(request).first {
                    /// Convert cache.feed[NSOrderedSet] into ManagedFeedImage and ManagedFeedImage into LocalFeedImage
                    completion(
                        .found(feed: cache.feed.compactMap{
                            $0 as? ManagedFeedImage
                        }.map{ feedImage in
                            LocalFeedImage(
                                id: feedImage.id,
                                description: feedImage.imageDescription,
                                location: feedImage.location,
                                url: feedImage.url
                            )
                        },
                               timestamp: cache.timestamp
                              )
                    )
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// COREDATA IMPL- INFRA IMPLEMENTATION
@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

private extension NSPersistentContainer {
    enum LoadingError: Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, url: URL ,bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        let description = NSPersistentStoreDescription(url: url)
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try? loadError.map{ throw LoadingError.failedToLoadPersistentStores($0) }
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap{ NSManagedObjectModel(contentsOf: $0) }
    }
}
