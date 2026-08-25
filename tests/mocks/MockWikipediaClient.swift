//
//  MockWikipediaClient.swift
//  nearby
//
//  Created by Max Myron on 5/2/26.
//

import MapKit
@testable import nearby

class MockWikipediaClient: WikipediaClientProtocol {
    func fetchLandmarks(at location: CLLocationCoordinate2D) async throws -> [WikipediaFetchSPARQLResponse] {
        return [
            .init(item: .init("1"), itemLabel: .init("New"), lat: .init(0.0), lon: .init(0.0), sitelink: .init("")),
            .init(item: .init("2"), itemLabel: .init("New 2"), lat: .init(0.0), lon: .init(0.0), sitelink: .init("")),
        ]
    }
}
