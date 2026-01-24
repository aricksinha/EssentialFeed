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
        sut.load{ _ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")
        let (sut, client) = makeSUT(url: url!)
        sut.load{ _ in }
        sut.load{ _ in }
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
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        /// since callback is async we will pass completion block- we get an error and we wanna capture this error
        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load { error in
                capturedErrors.append(error)
            }
            client.complete(withStatusCode: code, at: index)
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }

    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    // Only for test
    private class HTTPClientSpy: HTTPClient {
        private var messages: [(url: URL,completion: (Error?, HTTPURLResponse?) -> Void)] = []
        var requestedURLs: [URL]  {
            return messages.map{ $0.url }
        }
        func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
            let message = (url, completion)
            messages.append(message)
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error, nil)
        }
        
        func complete(withStatusCode statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            messages[index].completion(nil, response)
        }
    }
}
