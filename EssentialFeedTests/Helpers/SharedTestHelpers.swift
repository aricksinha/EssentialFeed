//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Aritra on 14/02/26.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any-error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
