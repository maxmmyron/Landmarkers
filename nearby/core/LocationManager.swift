//
//  LocationManager.swift
//  nearby
//
//  Created by Max Myron on 5/1/26.
//

import CoreLocation
import Combine
import SwiftData
import UserNotifications
import os

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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit)
    func updateLocationMonitoringMode(mode: LocationMonitoringMode)
    func requestImmediateLocation() async throws -> CLLocationCoordinate2D?
    func sendNotification(title: String, body: String)
}

@Observable
class LocationManager: NSObject, LocationManagerProtocol {
    let modelContainer: ModelContainer
    var fetchService: FetchServiceProtocol
    
    var location: CLLocationCoordinate2D? { lastLocation }
    
    private let manager = CLLocationManager()
    private var lastLocation: CLLocationCoordinate2D?
    private var lastTimestamp: Date = .distantPast
    private let logger = Logger(subsystem: "com.nearby.app", category: "LocationManager")
    
    init(modelContainer: ModelContainer, fetchService: FetchServiceProtocol) {
        self.modelContainer = modelContainer
        self.fetchService = fetchService
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestAlwaysAuthorization() // Required for CLVisit
        
        updateLocationMonitoringMode(mode: .ambient)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, err in
            if let err {
                Task { @MainActor in
                    self.logger.error("Notification auth failed: \(err.localizedDescription)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        
        if let last = lastLocation {
            if last.distance(from: coordinate) <= 1609.34 || lastTimestamp.timeIntervalSinceNow.magnitude <= 60 {
                return
            }
        }

        self.lastLocation = coordinate
        self.lastTimestamp = Date()
        
        Task {
            do {
                try await updateLandmarks(at: coordinate)
            } catch {
                logger.error("Failed to update landmarks on location change: \(error.localizedDescription)")
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // drop anything except for arrivals
        guard visit.departureDate == .distantFuture else { return }
        
        Task {
            let geohash = visit.coordinate.geohash(length: 6)
            
            do {
                try await updateLandmarks(at: visit.coordinate)
                
                let context = ModelContext(modelContainer)
                let descriptor = FetchDescriptor<MapCell>(predicate: #Predicate { $0.geohash == geohash })
                if let cell = try context.fetch(descriptor).first, let landmark = cell.landmarks.first {
                    sendNotification(title: "New Landmark!", body: "You arrived near \(landmark.name)")
                }
            } catch {
                logger.error("Failed ambient visit update in geohash \(geohash): \(error.localizedDescription)")
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("CoreLocation manager failed: \(error.localizedDescription)")
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
        do {
            for try await update in CLLocationUpdate.liveUpdates() {
                if let location = update.location {
                    self.lastLocation = location.coordinate
                    self.lastTimestamp = Date()
                    return location.coordinate
                }
            }
        } catch {
            logger.error("Live location stream error: \(error.localizedDescription)")
            throw error
        }
        return nil
    }
    
    internal func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Task { @MainActor in
                    self.logger.error("Failed to schedule notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateLandmarks(at coordinate: CLLocationCoordinate2D) async throws {
        let shouldFetch = try await Task.detached(priority: .utility) {
            let backgroundContext = ModelContext(self.modelContainer)
            backgroundContext.autosaveEnabled = false
            
            let visits = try backgroundContext.fetch(FetchDescriptor<Visit>())
            let isWithinOneMile = visits.contains { $0.distance(to: coordinate) <= 1609.34 }
            if isWithinOneMile { return false }
            
            backgroundContext.insert(Visit(coordinate: coordinate))
            try backgroundContext.save()
            return true
        }.value
        
        guard shouldFetch else { return }
        
        try await fetchService.synchronizeLandmarks(within: coordinate.geohash(length: 6))
    }
}
