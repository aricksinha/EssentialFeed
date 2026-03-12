//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Aritra on 22/02/26.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL
    ///Background queue but by-default op runs serially
    private let queue = DispatchQueue(
        label: "\(CodableFeedStore.self) Queue",
        qos: .userInitiated,
        attributes: .concurrent
    )
   public  init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL /// we are capturing the value and not self & they are pass by copy instead of ref
        queue.async {
            /// Decode the cache model  & then retrieve the feed and timestamp
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.success(.none))
            }
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.success(CachedFeed(feed: cache.localFeed, timestamp: cache.timestamp)))
            } catch {
                completion(.failure(error))
            }
        }
        
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL /// we are capturing the value and not self & they are pass by copy instead of ref
        queue.async(flags: .barrier) {
            do {
                /// hit the disk
                let encoder = JSONEncoder()
                let encoded = try! encoder.encode(
                    Cache(feed: feed.map{ CodableFeedImage(image: $0) },
                          timestamp: timestamp)
                )
                /// write the content to disk placed at storeURL - this url represents allocation in disk(it can be pvt detail)
                try encoded.write(to: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL /// we are capturing the value and not self & they are pass by copy instead of ref
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(.success(()))
            }
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
