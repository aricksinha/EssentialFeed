//
//  FeedRefreshViewController.swift
//  EssentialFeediOS
//
//  Created by Aritra on 22/03/26.
//

import Foundation
import UIKit
import EssentialFeed

final class FeedRefreshViewController: NSObject {
    private(set) lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        /// since refreshControl have load objc selector which is linked to Controller , so FeedRefreshVC : NSObject
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()
    
    private let feedLoader: FeedLoader
    
    var onRefresh: (([FeedImage]) -> Void)?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    @objc func refresh() {
        view.beginRefreshing()
        feedLoader.load{ [weak self] result in
            if let feed = try? result.get() {
                /// if request succeeds , its upto the client to do something with the result
                self?.onRefresh?(feed)
            }
            self?.view.endRefreshing()
        }
    }
}
