//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Aritra on 10/02/26.
//

import Foundation

/// RemoteFeedItem is internal represntation of Feed API module (DTO)
internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    /// this ** Item ** has right name that matches API JSON Representation
    internal let image: URL
}
