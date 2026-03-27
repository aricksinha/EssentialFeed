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
        /// Create a FeedViewModel
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        /// Create a refresh controller
        let refreshController = FeedRefreshViewController(viewModel: feedViewModel)
        /// Create a FeedVC- which can be used with in onRefresh closure
        let feedViewController = FeedViewController(
            refreshController: refreshController
        )
        feedViewModel.onFeedLoad = adaptFeedToCellController(
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
                FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: loader))
            }
        }
    }
}
