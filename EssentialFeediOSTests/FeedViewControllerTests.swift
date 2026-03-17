//
//  FeedViewControllerTests.swift
//  EssentialFeed
//
//  Created by Aritra on 16/03/26.
//

import XCTest
import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {

    func test_loadFeedActions_requestFeedsFromLoader() {
        let (sut, loader) = makeSUT()
            XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view is loaded")
            
            sut.loadViewIfNeeded()
            XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view is loaded")
            
            sut.simulateUserInitiatedFeedReload()
            XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")
            
            sut.simulateUserInitiatedFeedReload()
            XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
        
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        
        /// added index to tell whicjh completion block to invoke
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    
    func test_userInitiatedFeedReload_hideLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
    }

    //MARK: - Helpers
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeak(loader)
        trackForMemoryLeak(sut)
        return (sut, loader)
    }
    
    final class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        var loadCallCount: Int  {
            completions.count
        }
        
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(at index: Int) {
            completions[index](.success([]))
        }
    }
}

private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
