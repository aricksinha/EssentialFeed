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
        /// since callback is async we will pass completion block- we get an error and we wanna capture this error
        /// Give error a  better defination(custom error type inside RemoteFeedLoader) when client fails its a connectivity error
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { error in
            capturedErrors.append(error)
        }
        ///  its now upto us to test scope to invoke that completion block
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        XCTAssertEqual(capturedErrors, [.connectivity])
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
        var completions = [(Error) -> Void]()
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            /// THIS Error is Client error not DOMAIN error
            ///  we are not stubbing - we don't have beahviour in SPY
//            if let error = error {
//                completion(error)
//            }
            completions.append(completion)
            requestedURLs.append(url)
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index](error)
        }
    }
}
