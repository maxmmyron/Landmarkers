//
//  LocationManagerTests.swift
//  nearby
//
//  Created by Max Myron on 5/2/26.
//


import XCTest
import CoreLocation
@testable import nearby
import SwiftData

@MainActor
final class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!
    var fetchService: FetchService!
    var mockCLLocationManager: CLLocationManager!

    override func setUp() {
        super.setUp()
        
        mockCLLocationManager = CLLocationManager()
        let mockStorage = MockStorage()
        fetchService = FetchService(storage: mockStorage, wikipediaClient: MockWikipediaClient(), llmClient: MockLLMClient())
        locationManager =  LocationManager(storage: mockStorage, fetchService: fetchService)
    }
    
    override func tearDown() {
        locationManager = nil
        fetchService = nil
        super.tearDown()
    }
    
    func test_CLLocationManagerDelegateLocationCallbackUpdatesLocation() {
        let newCoord = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437)
        let mockLocation = CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude)
        
        // Manually trigger the delegate method
        locationManager.locationManager(mockCLLocationManager, didUpdateLocations: [mockLocation])
        
        XCTAssertEqual(self.locationManager.currentLocation!.latitude, 34.0522, accuracy: 0.0001)
        XCTAssertEqual(self.locationManager.currentLocation!.longitude, -118.2437, accuracy: 0.0001)
    }
    
    func test_CLLocationManagerDelegateVisitCallbackUpdatesLocation() {
        let newCoord = CLLocationCoordinate2D(latitude: 85.0522, longitude: -88.2437)
        let newDate = Date()
        
        let mockVisit = MockCLVisit(coordinate: newCoord, arrivalDate: newDate)
        
        locationManager.locationManager(mockCLLocationManager, didVisit: mockVisit)
        
        XCTAssertEqual(self.locationManager.currentLocation!.latitude, 85.0522, accuracy: 0.0001)
        XCTAssertEqual(self.locationManager.currentLocation!.longitude, -88.2437, accuracy: 0.0001)
    }
    
    func testDidVisitIgnoresDepartedVisits() {
        // set locationmanager location to some default
        locationManager.currentLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let locationBeforeCallback = locationManager.currentLocation!
        
        let mockVisit = MockCLVisit(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            arrivalDate: Date(timeIntervalSinceNow: -3600),
            departureDate: Date()  // Not .distantFuture
        )
        
        locationManager.locationManager(mockCLLocationManager, didVisit: mockVisit)
        
        XCTAssertEqual(locationManager.currentLocation!.latitude, locationBeforeCallback.latitude)
        XCTAssertEqual(locationManager.currentLocation!.longitude, locationBeforeCallback.longitude)
    }
}
