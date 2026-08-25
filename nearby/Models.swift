//
//  Models.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

import Foundation
import SwiftData
import CoreLocation

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
        [SchemaV2.Landmark.self, SchemaV1.VibeKeyword.self, SchemaV1.Landmark.self]
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
    }
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static let migrateV1ToV2 = MigrationStage.custom(fromVersion: SchemaV1.self, toVersion: SchemaV2.self) { context in
        let landmarks = try context.fetch(FetchDescriptor<SchemaV1.Landmark>())
        
        for landmark in landmarks {
            context.insert(SchemaV2.Landmark(
                pageid: String(landmark.pageid),
                title: landmark.title,
                summary: landmark.summary,
                latitude: landmark.latitude,
                longitude: landmark.longitude
            ));
        }
    } didMigrate: { _ in }
    
    static var stages: [MigrationStage] {
        [migrateV1ToV2]
    }
}

typealias Visit = SchemaV1.Visit
typealias VibeKeyword = SchemaV1.VibeKeyword
typealias Landmark = SchemaV1.Landmark
