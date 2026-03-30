//
//  FeedUIComposer.swift
//  EssentialFeediOS
//
//  Created by Aritra on 22/03/26.
//

import UIKit
import EssentialFeed

public final class FeedUIComposer {
    
    private init() { }
    
    public static func feedComposedWith(
        feedLoader: FeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> FeedViewController {
        /// Create a Feed Presenter
        let feedPresenter = FeedPresenter()
        let presentationAdapter = FeedLoaderPresentationAdapter(
            feedLoader: feedLoader,
            feedPresenter: feedPresenter
        )
        /// Create a refresh controller
        let refreshController = FeedRefreshViewController(
            loadFeed: presentationAdapter.loadFeed
        )
        /// Create a FeedVC- which can be used with in onRefresh closure
        let feedViewController = FeedViewController(
            refreshController: refreshController
        )
        feedPresenter.loadingView = WeakRefVirtualProxy(refreshController)
        feedPresenter.feedView = FeedViewAdapter(controller: feedViewController, imageLoader: imageLoader)
        return feedViewController
    }
}

private final class WeakRefVirtualProxy<T: AnyObject> {
    /// holds a weak ref object instance & pass the messages forward
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController? = nil, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { model in
            FeedImageCellController(viewModel: FeedImageViewModel(model: model, imageLoader: imageLoader, imageTransformer: UIImage.init))
        }
    }
}

private final class FeedLoaderPresentationAdapter {
    private let feedLoader: FeedLoader
    private let feedPresenter: FeedPresenter
    
    init(feedLoader: FeedLoader, feedPresenter: FeedPresenter) {
        self.feedLoader = feedLoader
        self.feedPresenter = feedPresenter
    }
    
    func loadFeed() {
        feedPresenter.didStartLoadingFeed()
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.feedPresenter.didFinishLoadingFeed(with: feed)
            case .failure(let error):
                self?.feedPresenter.didFinishLoadingFeed(with: error)
            }
        }
    }
}
