//
//  LLMAPIClient.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

import Foundation

protocol LLMClientProtocol {
    func filterArticles(_ articles: [WikipediaFetchSPARQLResponse], by vibes: [VibeKeyword]) async throws -> [WikipediaFetchSPARQLResponse]
    func determineVibes(from: String) async throws -> [VibeKeyword]
}

@MainActor
class LLMClient : LLMClientProtocol {
    private var apiKey: String {
        guard let key = Bundle.main.infoDictionary?["ApiKey"] as? String else {
            fatalError("API Key is missing from Info.plist")
        }
        return key
    }
    
    func filterArticles(_ articles: [WikipediaFetchSPARQLResponse], by vibes: [VibeKeyword]) async throws -> [WikipediaFetchSPARQLResponse] {
        let vibeStrings = vibes.map { $0.keyword }.joined(separator: ", ")
        _ = """
        User vibes: \(vibeStrings)
        Articles: \(articles.map { $0.itemLabel.value }.joined(separator: ", "))
        Directive: Return only those which are interesting based on the user vibes. Empty results are okay. Return as a comma-separated list of titles.
        """
        
        // TODO
        
        return articles
    }
    
    func determineVibes(from: String) async -> [VibeKeyword] {
        do {
            let response = try await call(agentMsg: "Decompose the sentence into 5 main 'vibes'.", userMsg: from)
            print("Successfully decomposed response: \(response)")
            return [VibeKeyword(keyword: "plants")]
        } catch {
            print("Failed to decompose sentence into vibes: \(error.localizedDescription)")
            return []
        }
    }
    
    private func call(agentMsg: String, userMsg: String) async throws -> ChatCompletionResponse {
        print("Getting URL")
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else {
            print("ERROR: Failed to get URL")
            throw URLError(.badURL)
        }
        
        print("Generating request...")
        let messages = [ Message(role: .system, content: agentMsg), Message(role: .user, content: userMsg) ]
        let body = ChatCompletionRequest(model: "deepseek-v4-flash", messages: messages, thinking: .init(type: .disabled), reasoningEffort: .none, stream: false)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        print("Request Generated!")
        
        print("Sending Request")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print(response)
            print("Failed to get 2XX response!")
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        print("successful decoding")
        return decoded
    }
}

// completion request

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let thinking: ThinkingConfig
    let reasoningEffort: ReasoningEffort
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model, messages, thinking
        case reasoningEffort = "reasoning_effort"
        case stream
    }
}

struct Message: Codable {
    let role: Role
    let content: String
    
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
}

struct ThinkingConfig: Codable {
    let type: ThinkingType
    
    enum ThinkingType: String, Codable {
        case enabled
        case disabled
    }
}

enum ReasoningEffort: String, Codable {
    case none
    case low
    case medium
    case high
}

// completion response

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let systemFingerprint: String?
    let choices: [Choice]
    let usage: Usage?

    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case systemFingerprint = "system_fingerprint"
    }
}

struct Choice: Codable {
    let index: Int
    let message: ResponseMessage
    let finishReason: FinishReason?

    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct ResponseMessage: Codable {
    let role: Role
    let content: String?
}

struct Usage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

enum Role: String, Codable {
    case system
    case user
    case assistant
    case tool
}

enum FinishReason: String, Codable {
    case stop
    case length
    case contentFilter = "content_filter"
    case toolCalls = "tool_calls"
}
