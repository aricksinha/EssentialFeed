//
//  XCTestCase+MemoryLeakTrackingHelper.swift
//  EssentialFeedTests
//
//  Created by Aritra on 31/01/26.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeak(
        _ instance: AnyObject,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential Memory Leak", file: file, line: line)
        }
    }
}
