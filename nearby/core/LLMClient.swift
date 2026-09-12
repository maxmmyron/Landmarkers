//
//  LLMAPIClient.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

import Foundation

protocol LLMClientProtocol {
    func determinePreferences(from sentence: String) async throws -> [LandmarkPreferenceDTO]
}

@MainActor
class LLMClient : LLMClientProtocol {
    private var apiKey: String {
        guard let key = Bundle.main.infoDictionary?["ApiKey"] as? String else {
            fatalError("API Key is missing from Info.plist")
        }
        return key
    }
    
    func determinePreferences(from sentence: String) async throws -> [LandmarkPreferenceDTO] {
        let agentMsg = """
            You are a precise data extraction assistant for a landmark discovery app. Your task is to analyze a user's natural language input and extract landmark preferences into a structured JSON array.

            ### Definitions
            - "vibe": Atmosphere, mood, aesthetic, or sensory feelings (e.g., "cozy", "bustling", "grungy", "secluded", "romantic", "quiet").
            - "classification": Concrete landmark types, functional categories, or architectural styles (e.g., "cafe", "historic site", "park", "rooftop bar", "art museum", "bookstore").

            ### Extraction Rules
            1. Format: Return a raw JSON array containing objects with exact keys: "type" and "value".
            2. Constraints:
               - "type" MUST be strictly either "vibe" or "classification".
               - "value" MUST be a short, clean, lowercase string.
            3. Quantity & Strictness:
               - If the input contains clear location/landmark intent or stylistic preferences, extract and expand at least 5 "vibe" items and 5 "classification" items based on the context.
               - Do NOT force weak matches. If the input is nonsense, irrelevant, or lacks clear preference signals, immediately return an empty array `[]`.

            ### Example Outputs

            Input: "I want a quiet, moody spot to read books and grab a dark coffee near old stone buildings."
            Output:
            [
              {"type": "vibe", "value": "quiet"},
              {"type": "vibe", "value": "moody"},
              {"type": "vibe", "value": "cozy"},
              {"type": "vibe", "value": "scholarly"},
              {"type": "vibe", "value": "intimate"},
              {"type": "classification", "value": "bookstore"},
              {"type": "classification", "value": "coffee shop"},
              {"type": "classification", "value": "library"},
              {"type": "classification", "value": "historic site"},
              {"type": "classification", "value": "old architecture"}
            ]

            Input: "What time does the train leave tomorrow?"
            Output:
            []
            """
        
        let userMsg = """
            Extract preferences from the following text:

            "\(sentence)"
            """
        
        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else { throw URLError(.badURL) }
        
        let body = ChatCompletionRequest(messages: [ .init(role: .system, content: agentMsg), .init(role: .user, content: userMsg) ])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let apiResponse = try decoder.decode(ChatCompletionResponse<[LandmarkPreferenceDTO]>.self, from: data)
        return try apiResponse.extractPayload(using: decoder)
    }
}

// completion request

struct ChatCompletionRequest: Encodable {
    var model: String = "deepseek-v4-flash"
    let messages: [Message]
    var thinking: ThinkingConfig? = .disabled
    var reasoningEffort: ReasoningEffort? = ChatCompletionRequest.ReasoningEffort.none
    var stream: Bool = false
    var responseFormat: ResponseFormat? = .jsonObject
    
    struct Message: Encodable {
        let role: Role
        let content: String
        
        enum Role: String, Encodable {
            case system, user, assistant, tool
        }
    }
    
    struct ThinkingConfig: Encodable {
        let type: ThinkingType
        
        enum ThinkingType: String, Encodable {
            case enabled, disabled
        }
        
        static let disabled = ThinkingConfig(type: .disabled)
        static let enabled = ThinkingConfig(type: .enabled)
    }
    
    enum ReasoningEffort: String, Encodable {
        case none, low, medium, high
    }
    
    struct ResponseFormat: Encodable {
        let type: String
        
        static let jsonObject = ResponseFormat(type: "json_object")
        static let text = ResponseFormat(type: "text")
    }
}

// completion response

struct ChatCompletionResponse<T: Decodable>: Decodable {
    let id: String?
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }

    func extractPayload(using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let content = choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Missing or empty response content string.")
            )
        }
        return try decoder.decode(T.self, from: data)
    }
}
