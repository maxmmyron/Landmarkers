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
    var latitude: Float32 = 0.0
    var longitude: Float32 = 0.0
    var timestamp: Date = Date()
    
    init(coordinate: CLLocationCoordinate2D, timestamp: Date = .now) {
        self.latitude = Float32(coordinate.latitude)
        self.longitude = Float32(coordinate.longitude)
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
    
    var cell: MapCell? = nil
    var latitude: Double
    var longitude: Double
    
    var dateRetrieved: Date

    var vibes: [String]
    var classifications: [String]
    
    init(wikidataID: String, name: String, summary: String, latitude: Double, longitude: Double, dateRetrieved: Date, vibes: [String], classifications: [String]) {
        self.wikidataID = wikidataID
        self.name = name
        self.summary = summary
        self.latitude = latitude
        self.longitude = longitude
        self.dateRetrieved = dateRetrieved
        self.vibes = vibes
        self.classifications = classifications
    }
    
    init(from dto: LandmarkDTO) {
        self.wikidataID = dto.wikidataID
        self.name = dto.name
        self.summary = dto.summary
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.dateRetrieved = .now
        self.vibes = dto.vibes
        self.classifications = dto.classifications
    }
    
    func update(from dto: LandmarkDTO) {
        self.wikidataID = dto.wikidataID
        self.name = dto.name
        self.summary = dto.summary
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.dateRetrieved = .now
        self.vibes = dto.vibes
        self.classifications = dto.classifications
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
