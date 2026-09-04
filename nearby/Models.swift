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
    
    var cell: MapCell
    var latitude: Float32
    var longitude: Float32
    
    var dateRetrieved: Date

    var vibes: [String]
    var classifications: [String]
    
    init(wikidataID: String, name: String, summary: String, latitude: Float32, longitude: Float32, dateRetrieved: Date, vibes: [String], classifications: [String]) {
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
        self.wikidataID = landmarkDTO.wikidataID
        self.name = landmarkDTO.name
        self.summary = landmarkDTO.summary
        self.latitude = landmarkDTO.latitude
        self.longitude = landmarkDTO.longitude
        self.dateRetrieved = .now
        self.vibes = landmarkDTO.vibes
        self.classifications = landmarkDTO.classifications
    }
    
    update(from dto: LandmarkDTO) {
        
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

/*
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [self.Visit.self, self.VibeKeyword.self, self.Landmark.self]
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
            let thisLocation = CLLocation(latitude: latitude, longitude: longitude)
            let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return thisLocation.distance(from: otherLocation)
        }
    }

    @Model
    class VibeKeyword {
        var keyword: String = ""
        
        init(keyword: String) {
            self.keyword = keyword
        }
    }

    @Model
    class Landmark {
        var pageid: Int = 0
        var title: String = ""
        var summary: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        
        init(pageid: Int, title: String, summary: String, latitude: Double, longitude: Double) {
            self.pageid = pageid
            self.title = title
            self.summary = summary
            self.latitude = latitude
            self.longitude = longitude
        }
        
        init(pageid: String, title: String, summary: String, latitude: Double, longitude: Double) {
            self.pageid = 0
            self.title = title
            self.summary = summary
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SchemaV2.Landmark.self, SchemaV1.VibeKeyword.self, SchemaV1.Visit.self]
    }
    
    @Model
    class Landmark {
        var pageid: String = ""
        var title: String = ""
        var summary: String = ""
        var latitude: Double = 0.0
        var longitude: Double = 0.0
        
        init(pageid: String, title: String, summary: String, latitude: Double, longitude: Double) {
            self.pageid = pageid
            self.title = title
            self.summary = summary
            self.latitude = latitude
            self.longitude = longitude
        }
        
        init (from landmark: SchemaV1.Landmark) {
            self.pageid = String(landmark.pageid)
            self.title = landmark.title
            self.summary = landmark.summary
            self.latitude = landmark.latitude
            self.longitude = landmark.longitude
        }
    }
}

enum SchemaV2_1: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SchemaV2_1.Landmark.self, SchemaV1.VibeKeyword.self, SchemaV2_1.Visit.self]
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
        
        init(from visit: SchemaV1.Visit) {
            self.latitude = Float32(visit.latitude)
            self.longitude = Float32(visit.longitude)
            self.timestamp = visit.timestamp
        }
        
        func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
            let thisLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return thisLocation.distance(from: otherLocation)
        }
    }

    
    @Model
    class Landmark {
        var pageid: String = ""
        var title: String = ""
        var summary: String = ""
        var latitude: Float32 = 0.0
        var longitude: Float32 = 0.0
        
        init(pageid: String, title: String, summary: String, latitude: Float32, longitude: Float32) {
            self.pageid = pageid
            self.title = title
            self.summary = summary
            self.latitude = latitude
            self.longitude = longitude
        }
        
        init(from landmark: SchemaV2.Landmark) {
            self.pageid = landmark.pageid
            self.title = landmark.title
            self.summary = landmark.summary
            self.latitude = Float32(landmark.latitude)
            self.longitude = Float32(landmark.longitude)
        }
    }
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV2_1.self]
    }
    
    private static var landmarksV2 = [SchemaV2.Landmark]()
    static let migrateV1ToV2 = MigrationStage.custom(fromVersion: SchemaV1.self, toVersion: SchemaV2.self) { context in
        let landmarks = try context.fetch(FetchDescriptor<SchemaV1.Landmark>())
        
        landmarksV2 = landmarks.map { SchemaV2.Landmark(from: $0) }
        
        try context.delete(model: SchemaV1.Landmark.self)
        try context.save()
    } didMigrate: { context in
        for landmark in landmarksV2 {
            context.insert(landmark)
        }
        try context.save()
    }
    
    private static var landmarksV2_1 = [SchemaV2_1.Landmark]()
    private static var visitsV2_1 = [SchemaV2_1.Visit]()
    static let migrateV2ToV2_1 = MigrationStage.custom(fromVersion: SchemaV2.self, toVersion: SchemaV2_1.self) { context in
        let landmarks = try context.fetch(FetchDescriptor<SchemaV2.Landmark>())
        let visits = try context.fetch(FetchDescriptor<SchemaV1.Visit>())
        
        landmarksV2_1 = landmarks.map { SchemaV2_1.Landmark(from: $0) }
        visitsV2_1 = visits.map { SchemaV2_1.Visit(from: $0) }
        
        try context.delete(model: SchemaV2.Landmark.self)
        try context.delete(model: SchemaV1.Visit.self)
        try context.save()
    } didMigrate: { context in
        for landmark in landmarksV2_1 {
            context.insert(landmark)
        }
        for visit in visitsV2_1 {
            context.insert(visit)
        }
        try context.save()
    }
    
    static var stages: [MigrationStage] {
        [migrateV1ToV2, migrateV2ToV2_1]
    }
}

typealias Visit = SchemaV2_1.Visit
typealias VibeKeyword = SchemaV1.VibeKeyword
typealias Landmark = SchemaV2_1.Landmark
*/
