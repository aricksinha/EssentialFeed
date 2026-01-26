//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Aritra on 25/01/26.
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
