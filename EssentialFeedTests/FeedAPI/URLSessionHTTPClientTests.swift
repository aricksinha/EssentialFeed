//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 29/01/26.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {
   
    override func setUp() {
        URLProtocolStub.startInterceptingRequest()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        /// observe all request with observer closure
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        makeSUT().get(from: url) { _ in }
        wait(for: [exp], timeout: 1.0)
    }
    
    /// Handle the Errors first
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        let error = receivedError as NSError?
        XCTAssertEqual(error?.domain, requestError.domain)
        XCTAssertEqual(error?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentableCases() {
        /// - **Case- 1** data: nil, response: nil, error:nil
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        /// - **Case- 2** data: nil, response: URLResponse, error:nil
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        /// - **Case- 4** data: value, response: nil, error:nil
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        /// - **Case- 5** data: value, response: nil, error:value
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        /// - **Case- 6** data: nil, URLResponse, error:value
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        /// - **Case- 7** data: nil, response: HTTPURLResponse, error:value
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        /// - **Case- 8** data: value, response: URLResponse, error:value
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        /// - **Case- 9** data: value, response: HTTPURLResponse, error:value
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        /// - **Case- 9** data: value, response: URLResponse, error:nil
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURL_suceedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let receivedValues = resultValues(data: data, response: response, error: nil)
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    // - **Case- 3** data: nil, response: HTTPURLResponse, error:nil
    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        
        let receivedValues = resultValues(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    //MARK: - Helpers
   private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private func anyData() -> Data {
        return Data("any-data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        var receivedError: Error?
        switch result {
        case .failure(let error):
            receivedError = error
        default:
            XCTFail("Expected success, got \(result) Instead", file: file, line: line)
        }
        return receivedError
    }
    
    private func resultValues(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        var receivedValues: (data: Data, response: HTTPURLResponse)?
        switch result {
        case let .success(data, response):
            receivedValues = (data, response)
        default:
            XCTFail("Expected success, got \(result) Instead", file: file, line: line)
        }
        return receivedValues
    }
    
    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    // APPROACH - 4 URLProtocol STUBBING
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        /// Now combine task and Error let make tuple/ struct
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        /// Stub with task
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        /// Observe all request
        static func observeRequest(observe: @escaping (URLRequest) -> Void) {
            /// capture the closure
            requestObserver = observe
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
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
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
