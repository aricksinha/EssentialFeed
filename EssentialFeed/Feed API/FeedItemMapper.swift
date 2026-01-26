//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Aritra on 25/01/26.
//

import Foundation

/// FeeditemMapper internal to this module , not accessible from any other module
internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
        var feed: [FeedItem] {
            self.items.map{ $0.item }
        }
    }
    /// Item is internal represntation of FeedItem - that contact API FeedItem
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        /// this ** Item ** has right name that matches API JSON Representation
        let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    private static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == OK_200,
            let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
        }
        return .success(root.feed)
    }
}
