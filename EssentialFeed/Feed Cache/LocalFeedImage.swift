//
//  LocalFeedImage.swift
//  EssentialFeed
//
//  Created by Aritra on 10/02/26.
//

import Foundation

/// This is a mirror currently for FeedItem but for local representation wrt **FeedCache module**
public struct LocalFeedImage: Equatable, Codable {
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
