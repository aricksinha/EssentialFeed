//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 21/01/26.
//

import Foundation

/// HTTPClient is public coz it can be implemented by external modules
public protocol HTTPClient {
    func get(from url: URL)
}

/// RemoteFeedLoader is public coz it can be implemented by external modules & it can even be created by another module so make init() also public
/// load() is behaviour of this class - tested outside so make it public
/// properties let it be private - noone is using it outside this class
/// N o use case of subclassing it-
public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        client.get(from: url)
    }
}
