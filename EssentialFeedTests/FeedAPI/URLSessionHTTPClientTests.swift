//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Aritra on 29/01/26.
//

import XCTest

class URLSessionHTTPClient {
    private let session: URLSession
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        /// Now we have to tell the session to stub the behavior of task
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url)
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    //MARK: - Helpers
    // APPROACH - 2 Subclass Based Mocking
    private class URLSessionSpy: URLSession {
        var receivedURLs: [URL] = []
        var stubs = [URL: URLSessionDataTask]()
        
        /// Everytime we invoke dataTask - receivedURLs gets appended[capturing the URL]
        /// think about what to return as we don't to execute a N/W request ever in test - we need a mock impl of URLSessionDataTask
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return stubs[url] ?? FakeURLSessionDataTask()
        }
        
        func stub(url: URL, task: URLSessionDataTask) {
            stubs[url] = task
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }
}
