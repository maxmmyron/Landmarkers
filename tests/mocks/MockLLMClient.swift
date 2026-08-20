//
//  MockWikipediaClient.swift
//  nearby
//
//  Created by Max Myron on 5/2/26.
//

import MapKit
@testable import nearby

@MainActor
class MockLLMClient: LLMClientProtocol {
    func filter(articles: [WikipediaPage], vibes: [VibeKeyword]) async throws -> [WikipediaPage] {
        return articles
    }
}
