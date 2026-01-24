//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 21/01/26.
//

import Foundation

public enum HTTPClientResult {
   case success(HTTPURLResponse)
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
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    /// Give load() a completion block : (Error) -> Void and in order to prevent breaking test
    public func load(completion: @escaping (Error) -> Void) {
        /// client calling with its completion handler and inside the closure contains the mapping from CLIENT Error -> DOMAIN Error
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.invalidData)
            case .failure:
                completion(.connectivity)
            }
        }
    }
}
