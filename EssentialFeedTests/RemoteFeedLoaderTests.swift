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
        XCTAssertEqual(client.requestedURLs, [])
    }
    
    // this is load items command in Usecase image
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")
        let (sut, client) = makeSUT(url: url!)
        sut.load()
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")
        let (sut, client) = makeSUT(url: url!)
        sut.load()
        sut.load()
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        client.error = NSError(domain: "Test", code: 0)
        /// since callback is async we will pass completion block- we get an error and we wanna capture this error
        /// Give error a  better defination(custom error type inside RemoteFeedLoader) when client fails its a connectivity error
        /// Currently there is no method to tell HTTPClient failed so this test will fail
        var capturedError: RemoteFeedLoader.Error?
        sut.load { error in
            capturedError = error
        }
        XCTAssertEqual(capturedError, .connectivity)
    }

    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Only for test
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var error: NSError?
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            /// THIS Error is Client error not DOMAIN error
            if let error = error {
                completion(error)
            }
            requestedURLs.append(url)
        }
    }
}
