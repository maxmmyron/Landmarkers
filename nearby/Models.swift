//
//  Models.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
class LandmarkPreference {
    enum PreferenceType: String, Codable {
        case vibe
        case classification
    }
    
    var type: PreferenceType
    var value: String
    
    init(type: PreferenceType, value: String) {
        self.type = type
        self.value = value
    }
    
    init(from dto: LandmarkPreferenceDTO) {
        self.type = dto.type
        self.value = dto.value
    }
}

@Model
class Visit {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var timestamp: Date = Date()
    
    init(coordinate: CLLocationCoordinate2D, timestamp: Date = .now) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = timestamp
    }
    
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let thisLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return thisLocation.distance(from: otherLocation)
    }
}


@Model
class Landmark {
    @Attribute(.unique) var wikidataID: String
    var name: String
    var summary: String
    var latitude: Double
    var longitude: Double
    var geohash: String
    var updatedAt: Date
    
    // computed fields
    var dateRetrieved: Date = Date.now

    var cell: MapCell? = nil
    var vibes: [String] = []
    var classifications: [String] = []
    
    init(wikidataID: String, name: String, summary: String, latitude: Double, longitude: Double, geohash: String, updatedAt: Date) {
        self.wikidataID = wikidataID
        self.name = name
        self.summary = summary
        self.latitude = latitude
        self.longitude = longitude
        self.geohash = geohash
        self.updatedAt = updatedAt
    }
    
    init(from dto: LandmarkFetchDTO) {
        self.wikidataID = dto.wikidataID
        self.name = dto.name
        self.summary = dto.summary
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.geohash = dto.geohash
        self.updatedAt = dto.updatedAt
    }
    
    func update(from dto: LandmarkFetchDTO) {
        self.wikidataID = dto.wikidataID
        self.name = dto.name
        self.summary = dto.summary
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.geohash = dto.geohash
        self.updatedAt = dto.updatedAt
    }
    
    func toUpsertDTO() -> LandmarkUpsertDTO {
        return .init(wikidataID: wikidataID, name: name, summary: summary, latitude: latitude, longitude: longitude)
    }
}


@Model
class MapCell {
    @Attribute(.unique) var geohash: String
    var dateModified: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Landmark.cell)
    var landmarks: [Landmark] = []
    
    init(geohash: String, dateModified: Date = .now) {
        self.geohash = geohash
        self.dateModified = dateModified
    }
}
