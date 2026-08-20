//
//  MockWikipediaClient.swift
//  nearby
//
//  Created by Max Myron on 5/2/26.
//

import MapKit
@testable import nearby

class MockWikipediaClient: WikipediaClientProtocol {
    func fetchLandmarks(at location: CLLocationCoordinate2D) async throws -> [WikipediaPage] {
        return [
            .init(pageid: 1, title: "New", lat: 0.0, lon: 0.0, dist: 0),
            .init(pageid: 2, title: "New 2", lat: 0.1, lon: 0.1, dist: 1)
        ]
    }
}
