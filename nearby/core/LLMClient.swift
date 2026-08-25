//
//  LLMAPIClient.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

protocol LLMClientProtocol {
    func filter(articles: [WikipediaFetchSPARQLResponse], vibes: [VibeKeyword]) async throws -> [WikipediaFetchSPARQLResponse]
}

@MainActor
class LLMClient : LLMClientProtocol {
    func filter(articles: [WikipediaFetchSPARQLResponse], vibes: [VibeKeyword]) async throws -> [WikipediaFetchSPARQLResponse] {
        let vibeStrings = vibes.map { $0.keyword }.joined(separator: ", ")
        let prompt = """
        User vibes: \(vibeStrings)
        Articles: \(articles.map { $0.itemLabel.value }.joined(separator: ", "))
        Directive: Return only those which are interesting based on the user vibes. Empty results are okay. Return as a comma-separated list of titles.
        """
        
        // TODO
        
        return articles
    }
}
