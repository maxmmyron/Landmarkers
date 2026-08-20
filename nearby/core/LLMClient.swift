//
//  LLMAPIClient.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

protocol LLMClientProtocol {
    func filter(articles: [WikipediaPage], vibes: [VibeKeyword]) async throws -> [WikipediaPage]
}

@MainActor
class LLMClient : LLMClientProtocol {
    func filter(articles: [WikipediaPage], vibes: [VibeKeyword]) async throws -> [WikipediaPage] {
        let vibeStrings = vibes.map { $0.keyword }.joined(separator: ", ")
        let prompt = """
        User vibes: \(vibeStrings)
        Articles: \(articles.map { $0.title }.joined(separator: ", "))
        Directive: Return only those which are interesting based on the user vibes. Empty results are okay. Return as a comma-separated list of titles.
        """
        
        // TODO
        
        return articles
    }
}
