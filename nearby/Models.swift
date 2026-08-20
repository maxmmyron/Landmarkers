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
}
