//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Aritra on 14/02/26.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let locals = models.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (models, locals)
}

///Date Extension that handles cache policy
extension Date {
    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
    
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
}

/// Date extension for other helper function
extension Date {
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
}

