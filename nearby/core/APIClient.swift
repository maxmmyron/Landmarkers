//
//  APIClient.swift
//  nearby
//
//  Created by Max Myron on 9/4/26.
//

import Foundation
import Supabase
    
protocol APIClientProtocol {
    // fetches landmarks from API
    func fetchLandmarks(geohash: String) async throws -> [LandmarkFetchDTO]
    func updateLandmark(with data: LandmarkUpsertDTO) async throws
}

class APIClient: APIClientProtocol {
    private let client: SupabaseClient
    
    init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://rwayjlwlbsnoeuwfyqjb.supabase.co")!,
            supabaseKey: "sb_publishable_z1U5W3baKmdhjsJRL2AHrw_uJN9oSrH"
        )
    }
    
    func fetchLandmarks(geohash: String) async throws -> [LandmarkFetchDTO] {
        guard let location = Geohash.decode(hash: geohash) else { return [] }
        print("Fetching landmarks for geohash: \(geohash)")
        
        struct RPCCoords: Codable {
            let user_lat: Double
            let user_lng: Double
            
            init(_ location: (latitude: (min: Double, max: Double), longitude: (min: Double, max: Double))) {
                self.user_lat = (location.latitude.max + location.latitude.min) / 2
                self.user_lng = (location.longitude.max + location.longitude.min) / 2
            }
        }

        let landmarks: [LandmarkFetchDTO] = try await client
            .rpc("get_nearest_landmarks", params: RPCCoords(location))
            .execute()
            .value
        
        print("found \(landmarks.count) landmarks!")
        return landmarks
    }
    
    func updateLandmark(with data: LandmarkUpsertDTO) async throws {
        try await client.rpc("upsert_landmark", params: data).execute()
    }
}

/// The landmark data transfer object used when receiveing landmarks from supabase
struct LandmarkFetchDTO: Codable {
    var wikidataID: String
    var name: String
    var summary: String
    var latitude: Double
    var longitude: Double
    var geohash: String
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case wikidataID = "wikidata_id"
        case name, summary, latitude, longitude, geohash
        case updatedAt = "updated_at"
    }
}

/// the landmark data transfer object used when sending landmarks to supabase
struct LandmarkUpsertDTO: Codable {
    var wikidataID: String
    var name: String
    var summary: String
    var latitude: Double
    var longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case wikidataID = "wikidata_id"
        case name, summary, latitude, longitude
    }
}

struct LandmarkPreferenceDTO: Codable {
    var type: LandmarkPreference.PreferenceType
    var value: String
}
