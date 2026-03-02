//
//  ManagedFeedImage.swift
//  EssentialFeed
//
//  Created by Aritra on 01/03/26.
//

import CoreData

@objc(ManagedFeedImage)
internal class ManagedFeedImage: NSManagedObject {
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
