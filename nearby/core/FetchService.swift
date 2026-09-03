//
//  FetchService.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

import Foundation
import SwiftData
import CoreLocation

protocol FetchServiceProtocol {
    func fetchAndStoreNewLandmarks(at coordinate: CLLocationCoordinate2D) async throws -> [Landmark]
    func fetchAndStoreVibes(from sentence: String) async throws -> [VibeKeyword]
    var wikipediaClient: WikipediaClientProtocol { get }
}

@Observable
class FetchService: FetchServiceProtocol {
    let storage: StorageProtocol
    let wikipediaClient: WikipediaClientProtocol
    private let llmClient: LLMClientProtocol
    
    init(storage: StorageProtocol, wikipediaClient: WikipediaClientProtocol, llmClient: LLMClientProtocol) {
        self.storage = storage
        self.wikipediaClient = wikipediaClient
        self.llmClient = llmClient
    }
    
    @MainActor
    func fetchAndStoreNewLandmarks(at coordinate: CLLocationCoordinate2D) async throws -> [Landmark] {
        let newArticles = await fetchNewArticles(coordinate: coordinate)
        print("fetched: \(newArticles.count)")
        guard !newArticles.isEmpty else { return [] }
        
        let interestingArticles = await filterToInterestingArticles(articles: newArticles)
        print("interesting: \(interestingArticles.count)")
        guard !interestingArticles.isEmpty else { return [] }
        
        var newLandmarks: [Landmark] = []
        for article in interestingArticles {
            let landmark = Landmark(
                pageid: article.item.value,
                title: article.itemLabel.value,
                summary: "Nearby point of interest.", // Optionally fetch wiki summary here
                latitude: Float32(article.lat.value),
                longitude: Float32(article.lon.value)
            )
            newLandmarks.append(landmark)
        }
        
        try? await storage.save(newLandmarks)
        return newLandmarks
    }
    
    @MainActor
    func fetchAndStoreVibes(from sentence: String) async throws -> [VibeKeyword] {
        print("Fetching vibes from \(sentence)")
        let vibes = (try? await llmClient.determineVibes(from: sentence)) ?? []
        
        try? await storage.save(vibes)
        return vibes
    }
    
    private func fetchNewArticles(coordinate: CLLocationCoordinate2D) async -> [WikipediaFetchSPARQLResponse] {
        guard let articles = try? await wikipediaClient.fetchLandmarks(at: coordinate) else {
            return []
        }
        
        let existingLandmarks = await storage.getExistingLandmarks()
        if existingLandmarks.isEmpty { return articles }
        
        // let existingIDs = Set(existingLandmarks.map { $0.pageid })
        
        return articles
        
        // return articles.filter { !existingIDs.contains($0.item.value) }
    }
    
    private func filterToInterestingArticles(articles: [WikipediaFetchSPARQLResponse]) async -> [WikipediaFetchSPARQLResponse] {
        let vibes = await storage.getVibes()
        if vibes.isEmpty { return [] }
        
        return (try? await llmClient.filterArticles(articles, by: vibes)) ?? []
    }
}
