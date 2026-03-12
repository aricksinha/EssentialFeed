//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Aritra on 25/01/26.
//

import Foundation

/// HTTPClient is public coz it can be implemented by external modules
public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
