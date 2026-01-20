//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 19/01/26.
//

import XCTest

class RemoteFeedLoader {
    let client: HTTPClient
    
    init(client: HTTPClient) { self.client = client }
    
    func load() {
        client.get(from: URL(string: "https://a-url.com"))
    }
}

protocol HTTPClient {
    func get(from url: URL?)
}

// Only for test
class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func get(from url: URL?) {
        requestedURL = url
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    // we don't have the URL for api call - lets see the request from another angle i.e if we don't call load() , client.requestedURL is not requested
    // Lets add the client we mentioned
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
        
        XCTAssertNil(client.requestedURL)
    }
    
    // this is load items command in Usecase image
    func test_load_requestDataFromURL() {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        sut.load()
        XCTAssertNotNil(client.requestedURL)
        
    }

}
