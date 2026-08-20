//
//  LocationManager.swift
//  nearby
//
//  Created by Max Myron on 5/1/26.
//

import CoreLocation
import Combine
import SwiftData
import CoreLocation
import UserNotifications

enum LocationMonitoringMode {
    case ambient
    case live
}

extension CLLocationCoordinate2D {
    func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance {
        let selfLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let otherLocation = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return selfLocation.distance(from: otherLocation)
    }
}

@MainActor
protocol LocationManagerProtocol: NSObjectProtocol, CLLocationManagerDelegate {
    /// Runs in active mode and updates Landmarks model based on valid `CLLocation`.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    /// Runs in passive move and updates Landmark model based on valid `CLVisit`
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit)
    
    func updateLocationMonitoringMode(mode: LocationMonitoringMode)
    
    func requestImmediateLocation() async throws -> CLLocationCoordinate2D?
    
    func sendNotification(title: String, body: String)
}

@Observable
class LocationManager: NSObject, LocationManagerProtocol {
    var storage: StorageProtocol
    var fetchService: FetchServiceProtocol
    var location: CLLocationCoordinate2D? {
        get { lastLocation }
    }
    
    private let manager = CLLocationManager()
    private var lastLocation: CLLocationCoordinate2D?
    private var lastTimestamp: Date = .distantPast
    
    init(storage: StorageProtocol, fetchService: FetchServiceProtocol) {
        self.storage = storage
        self.fetchService = fetchService
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestAlwaysAuthorization() // Required for CLVisit
        manager.startUpdatingLocation()
        manager.startMonitoringVisits()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        
        // must be > 1 mi from last location and > 60 seconds since last fetch
        if lastLocation != nil {
            if lastLocation!.distance(from: coordinate) <= 1609.34 || lastTimestamp.timeIntervalSinceNow.magnitude <= 60 { return }
        }

        self.lastLocation = coordinate
        self.lastTimestamp = Date()
        
        
        Task {
            let _ = await updateLandmarks(at: coordinate)
         
            // don't notify during live fetching, for now
//            if !newLandmarks.isEmpty {
//                sendNotification(title: "New Landmark Nearby!", body: "Found \(newLandmarks.first!.title) based on your vibe.")
//            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // drop anything except for arrivals
        guard visit.departureDate == .distantFuture else { return }
        
        Task {
            let newLandmarks = await updateLandmarks(at: visit.coordinate)
            
            if !newLandmarks.isEmpty {
                sendNotification(title: "New Landmark Nearby!", body: "Found \(newLandmarks.first!.title) based on your vibe.")
            }
        }
    }
    
    func updateLocationMonitoringMode(mode: LocationMonitoringMode) {
        switch mode {
        case .ambient:
            manager.stopUpdatingLocation()
            manager.startMonitoringVisits()
        case .live:
            manager.stopMonitoringVisits()
            manager.startUpdatingLocation()
        }
    }
    
    func requestImmediateLocation() async throws -> CLLocationCoordinate2D? {
        for try await update in CLLocationUpdate.liveUpdates() {
            if let location = update.location {
                self.lastLocation = location.coordinate
                self.lastTimestamp = Date()
                return location.coordinate
            }
        }
        return nil
    }
    
    internal func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func updateLandmarks(at coordinate: CLLocationCoordinate2D) async -> [Landmark] {
        let existingVisits = await storage.getVisits()
        let isWithinOneMile = existingVisits.contains { existing in
            existing.distance(to: coordinate) <= 1609.34
        }
        
        if isWithinOneMile { return [] }
        
        try? await storage.save([Visit(coordinate: coordinate)])
        
        return (try? await fetchService.runFetchFlow(at: coordinate)) ?? []
    }
}
