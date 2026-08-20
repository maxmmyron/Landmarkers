//
//  WikipediaClient.swift
//  nearby
//
//  Created by Max Myron on 5/1/26.
//

import Foundation
import SwiftData
import MapKit

protocol WikipediaClientProtocol {
    func fetchLandmarks(at location: CLLocationCoordinate2D) async throws -> [WikipediaPage]
}

@MainActor
class WikipediaClient: WikipediaClientProtocol {
    func fetchLandmarks(at location: CLLocationCoordinate2D) async throws -> [WikipediaPage] {
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=\(location.latitude)|\(location.longitude)&gsradius=10000&gslimit=50&format=json"
        
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WikipediaResponse.self, from: data)
        return response.query.geosearch
    }
}

struct WikipediaResponse: Codable {
    let query: WikipediaQuery
}

struct WikipediaQuery: Codable {
    let geosearch: [WikipediaPage]
}

struct WikipediaPage: Codable {
    let pageid: Int
    let title: String
    let lat: Double
    let lon: Double
    let dist: Double // Distance in meters from your coordinate
}
