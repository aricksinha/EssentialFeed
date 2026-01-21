//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 19/01/26.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

    // we don't have the URL for api call - lets see the request from another angle i.e if we don't call load() , client.requestedURL is not requested
    // Lets add the client we mentioned
    func test_init_doesNotRequestDataFromURL() {
        let (sut, client) = makeSUT()
        XCTAssertNil(client.requestedURL)
    }
    
    // this is load items command in Usecase image
    func test_load_requestDataFromURL() {
        let (sut, client) = makeSUT(
            url: URL(string: "https://a-url.com")!
        )
        sut.load()
        XCTAssertEqual(client.requestedURL, URL(string: "https://a-url.com"))
    }

    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Only for test
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL?) {
            requestedURL = url
        }
    }
}
