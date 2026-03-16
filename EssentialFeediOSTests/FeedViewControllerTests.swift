//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Aritra on 16/03/26.
//

import XCTest

//MARK: - Prod Code
final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {
        
    }
}
//MARK: - Test Code
final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    //MARK: - Helpers
    final class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}
