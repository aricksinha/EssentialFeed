//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Aritra on 25/01/26.
//

import Foundation

/// Item is internal represntation of Feed API module (DTO)
internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    /// this ** Item ** has right name that matches API JSON Representation
    internal let image: URL
}

/// FeeditemMapper internal to this module , not accessible from any other module
internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    private static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
            let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return root.items
    }
}
