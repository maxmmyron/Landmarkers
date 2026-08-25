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
    func runFetchFlow(at coordinate: CLLocationCoordinate2D) async throws -> [Landmark]
    var wikipediaClient: WikipediaClientProtocol { get }
}

@Observable
class FetchService: FetchServiceProtocol {
    let storage: StorageProtocol
    let wikipediaClient: WikipediaClientProtocol
    let llmClient: LLMClientProtocol
    
    init(storage: StorageProtocol, wikipediaClient: WikipediaClientProtocol, llmClient: LLMClientProtocol) {
        self.storage = storage
        self.wikipediaClient = wikipediaClient
        self.llmClient = llmClient
    }
    
    @MainActor
    func runFetchFlow(at coordinate: CLLocationCoordinate2D) async throws -> [Landmark] {
        let newArticles = await fetchNewArticles(coordinate: coordinate)
        guard !newArticles.isEmpty else { return [] }
        
        let interestingArticles = await filterOutUninterestingArticles(articles: newArticles)
        guard !interestingArticles.isEmpty else { return [] }
        
        var newLandmarks: [Landmark] = []
        for article in interestingArticles {
            let landmark = Landmark(
                pageid: article.item.value,
                title: article.itemLabel.value,
                summary: "Nearby point of interest.", // Optionally fetch wiki summary here
                latitude: article.lat.value,
                longitude: article.lon.value
            )
            newLandmarks.append(landmark)
        }
        
        try? await storage.save(newLandmarks)
        return newLandmarks
    }
    
    private func fetchNewArticles(coordinate: CLLocationCoordinate2D) async -> [WikipediaFetchSPARQLResponse] {
        guard let articles = try? await wikipediaClient.fetchLandmarks(at: coordinate) else {
            return []
        }
        
        let existingLandmarks = await storage.getExistingLandmarks()
        if existingLandmarks.isEmpty { return [] }
        
        let existingIDs = Set(existingLandmarks.map { $0.pageid })
        
        return articles
        
//        return articles.filter { !existingIDs.contains($0.item.value) }
    }
    
    private func filterOutUninterestingArticles(articles: [WikipediaFetchSPARQLResponse]) async -> [WikipediaFetchSPARQLResponse] {
        let vibes = await storage.getVibes()
        if vibes.isEmpty { return [] }
        
        return (try? await llmClient.filter(articles: articles, vibes: vibes)) ?? []
    }
}
