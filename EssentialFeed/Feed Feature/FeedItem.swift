//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Aritra on 17/01/26.
//

import Foundation

/// this is normal struct Model that represents FeedFeature.FeedItem representation
public struct FeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
