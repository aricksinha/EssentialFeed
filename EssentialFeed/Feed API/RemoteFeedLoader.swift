//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 21/01/26.
//

import Foundation

public enum HTTPClientResult {
   case success(Data, HTTPURLResponse)
   case failure(Error)
}

/// HTTPClient is public coz it can be implemented by external modules
public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

/// RemoteFeedLoader is public coz it can be implemented by external modules & it can even be created by another module so make init() also public
/// load() is behaviour of this class - tested outside so make it public
/// properties let it be private - noone is using it outside this class
/// No use case of subclassing it-
public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
       case connectivity
       case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    /// Give load() a completion block : (Result) -> Void 
    public func load(completion: @escaping (Result) -> Void)  {
        /// client calling with its completion handler and inside the closure contains the mapping from CLIENT Error -> DOMAIN Error
        client.get(from: url) { result in
            switch result {
            case .success(let data, let response):
                /// JSONSerialization is also a singleton with small s like URLSession(Refer lecture -1)
                if response.statusCode == 200,let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.items.map{
                        /// mapping API.Item(Decodable) to FeedItem normal struct
                        $0.item
                    }))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private struct Root: Decodable {
    let items: [Item]
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
