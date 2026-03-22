//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Aritra on 22/03/26.
//

import Foundation
import EssentialFeed

public final class FeedUIComposer {
    
    private init() { }
    
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        /// Create a refresh controller
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        /// Create a FeedVC- which can be used with in onRefresh closure
        let feedViewController = FeedViewController(
            refreshController: refreshController
        )
        refreshController.onRefresh = adaptFeedToCellController(
            forwardTo: feedViewController,
            loader: imageLoader
        )
        return feedViewController
    }
    
    private static func adaptFeedToCellController(
        forwardTo controller: FeedViewController,
        loader: FeedImageDataLoader
    ) -> ([FeedImage]) -> Void {
       return  { [weak controller] feed in
            controller?.tableModel = feed.map { model in
                FeedImageCellController(model: model, imageLoader: loader)
            }
        }
    }
}
