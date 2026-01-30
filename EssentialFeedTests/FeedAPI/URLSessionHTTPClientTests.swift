//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 29/01/26.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?,(any Error)?) -> Void
    ) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession
    init(session: HTTPSession) {
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
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let task = URLSessionDataTaskSpy()
        /// Now we have to tell the session to stub the behavior of task
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    /// Handle the Errors first
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "any-error", code: 1)
        /// Now we have to tell the session to stub with an error and make sure we complete with same error
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
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
    }
    
    //MARK: - Helpers
    // APPROACH - 3 Protocol Based Mocking
    private class HTTPSessionSpy: HTTPSession {
        private var stubs = [URL: Stub]()
        /// Now combine task and Error let make tuple/ struct
        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }
        
        func dataTask(
            with url: URL,
            completionHandler: @escaping (Data?, URLResponse?,(any Error)?) -> Void
        ) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            /// Call completion handler
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
        
        /// Stub with task
        func stub(
            url: URL,
            task: HTTPSessionTask = FakeURLSessionDataTask(),
            error: Error? = nil
        ) {
            stubs[url] = Stub(task: task, error: error)
        }
    }
    
    private class FakeURLSessionDataTask: HTTPSessionTask {
        func resume() {}
    }
    
    private class URLSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
