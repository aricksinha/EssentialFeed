//
//  FeedImage.swift
//  EssentialFeed
//
//  Created by Aritra on 17/01/26.
//

import Foundation

/// this is normal struct Model that represents FeedFeature.FeedItem representation
public struct FeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
