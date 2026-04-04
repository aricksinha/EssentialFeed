//
//  FeedImageViewModel.swift
//  EssentialFeediOS
//
//  Created by Aritra on 30/03/26.
//

import Foundation

struct FeedImageViewModel<Image> {
    let description: String?
    let location: String?
    let image: Image?
    let isLoading: Bool
    let shouldRetry: Bool
    
    var hasLocation: Bool {
        return location != nil
    }
}
