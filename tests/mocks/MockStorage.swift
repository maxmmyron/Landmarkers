//
//  MockLandmarkStorage.swift
//  nearby
//
//  Created by Max Myron on 8/13/26.
//

@testable import nearby
import SwiftData

@MainActor
final class MockStorage: StorageProtocol {
    var landmarks: [nearby.Landmark] = []
    var vibes: [nearby.VibeKeyword] = []
    var visits: [Visit] = []
    
    func getExistingLandmarks() async -> [nearby.Landmark] {
        return landmarks
    }
    
    func getVibes() async -> [nearby.VibeKeyword] {
        return vibes
    }
    
    func getVisits() async -> [Visit] {
        return visits
    }
    
    func save<T>(_ models: [T]) async throws where T : PersistentModel {
        if let newLandmarks = models as? [nearby.Landmark] {
            landmarks.append(contentsOf: newLandmarks)
        } else if let newVibes = models as? [nearby.VibeKeyword] {
            vibes.append(contentsOf: newVibes)
        } else if let newVisits = models as? [Visit] {
            visits.append(contentsOf: newVisits)
        }
    }
}
