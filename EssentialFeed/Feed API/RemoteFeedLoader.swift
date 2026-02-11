//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 21/01/26.
//

import Foundation

/// RemoteFeedLoader is public coz it can be implemented by external modules & it can even be created by another module so make init() also public
/// load() is behaviour of this class - tested outside so make it public
/// properties let it be private - noone is using it outside this class
/// No use case of subclassing it-
public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
       case connectivity
       case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    /// Give load() a completion block : (Result) -> Void 
    public func load(completion: @escaping (Result) -> Void)  {
        /// client calling with its completion handler and inside the closure contains the mapping from CLIENT Error -> DOMAIN Error
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .success(let data, let response):
                let result = RemoteFeedLoader.map(data, from: response)
               completion(result)
            case .failure:
                /// this Error is Domain specific error
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let remoteFeedItems = try FeedItemsMapper.map(data, response: response)
             return .success(remoteFeedItems.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModels() -> [FeedImage] {
       return self.map{
            FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image)
        }
    }
}

