//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by Aritra on 01/03/26.
//

import CoreData

@objc(ManagedCache)
internal class ManagedCache: NSManagedObject {
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
