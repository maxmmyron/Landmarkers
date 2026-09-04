//
//  APIClient.swift
//  nearby
//
//  Created by Max Myron on 9/4/26.
//

import Foundation

protocol APIClientProtocol {
    // fetches landmarks from API
    func fetchLandmarks(geohash: String) async throws -> [LandmarkDTO]
    
    // turns onboarding vibe input into a series of preferences.
    func composeUserVibes(_ sentence: String) async throws -> [APILandmarkPreference]
}

class APIClient: APIClientProtocol {
    func fetchLandmarks(geohash: String) async throws -> [LandmarkDTO] {
        // TODO: implement actual request.
        
        return [
            
        ]
    }
    
    func composeUserVibes(_ sentence: String) async throws -> [APILandmarkPreference] {
        <#code#>
    }
}

struct LandmarkDTO: Codable {
    var wikidataID: String
    var name: String
    var summary: String
    
    var latitude: Float32
    var longitude: Float32
    
//    var dateRetrieved: Date

    var vibes: [String]
    var classifications: [String]
}

struct APILandmarkPreference: Codable {
    
}
