//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 29/01/26.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(
        from url: URL,
        completion: @escaping (HTTPClientResult) -> Void
    ) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    /// Handle the Errors first
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequest()
        
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any-error", code: 1)
        /// Stubbing error with URLProtocol subclass
        URLProtocolStub.stub(
            data: nil,
            response: nil,
            error: error
        )
        let sut = URLSessionHTTPClient()
        /// Make sure to get the error in result - get() needs a completion block add it  **URLSessionHTTPClient** prod code
        /// But this get() completion is async block better guarnatee we go inside block using **Expectation**
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            default:
                XCTFail("Expected Failure with error \(error) got \(result) Instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequest()
    }
    
    //MARK: - Helpers
    // APPROACH - 4 URLProtocol STUBBING
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        /// Now combine task and Error let make tuple/ struct
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        /// Stub with task
        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error?
        ) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
        }
        
        /// Returning true as we want to intercept all request
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        /// Instance method - start loading the URL
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                /// tells the client that we loaded some data
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
