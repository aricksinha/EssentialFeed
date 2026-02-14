//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Aritra on 08/02/26.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calender = Calendar(identifier: .gregorian)
    private var maxCacheAgeInDays: Int {
        return 7
    }
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

//MARK: - Cache Feed UseCase
extension LocalFeedLoader {
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                /// this block says there is an error
                completion(cacheDeletionError)
            } else {
                /// there is no error so complete insertion
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(
        _ feed: [FeedImage],
        with completion: @escaping (SaveResult) -> Void
    ) {
        store.insert(feed.toLocal(), timestamp: self.currentDate(), completion: { [weak self] error in
                /// if LocalFeedLoader is deallocated - don't let the code block to execute anymore
                guard self != nil else { return }
                completion(error)
            }
        )
    }
}

//MARK: -  Load Feed From Cache UseCase
extension LocalFeedLoader: FeedLoader {
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
        
                completion(.failure(error))
            case .found(feed: let feed, timestamp: let timestamp) where self.validate(timestamp):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
                
            }
        }
    }
}

//MARK: -  Validate Cache UseCase
extension LocalFeedLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                self.store.deleteCachedFeed { _ in }
            /// found a cache but its not valid
            case .found(_, let timestamp) where !validate(timestamp):
                self.store.deleteCachedFeed { _ in }
            case .empty, .found: break
            }
        }
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calender.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        return currentDate() < maxCacheAge
    }
}

extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map{
            LocalFeedImage(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                url: $0.url
            )
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
       return self.map{
           FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}
