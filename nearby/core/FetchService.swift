//
//  FetchService.swift
//  nearby
//
//  Created by Max Myron on 8/12/26.
//

import Foundation
import SwiftData
import CoreLocation

protocol FetchServiceProtocol {
    func synchronizeLandmarks(within geohash: String) async throws
    func synchronizePreferences(from sentence: String) async throws
}

@Observable
class FetchService: FetchServiceProtocol {
    private let ninetyDaysInSeconds: TimeInterval = 60 * 60 * 24 * 90
    
    let modelContainer: ModelContainer
    let apiClient: APIClientProtocol
    let llmClient: LLMClientProtocol
    
    init(modelContainer: ModelContainer, apiClient: APIClientProtocol, llmClient: LLMClientProtocol) {
        self.modelContainer = modelContainer
        self.apiClient = apiClient
        self.llmClient = llmClient
    }
    
    func synchronizeLandmarks(within geohash: String) async throws {
        let backgroundContext = ModelContext(self.modelContainer)
        backgroundContext.autosaveEnabled = false
        
        // cancel fetch if there's a non-stale cell.
        let cellDescriptor = FetchDescriptor<MapCell>(predicate: #Predicate { $0.geohash == geohash })
        let existingCell = try backgroundContext.fetch(cellDescriptor).first
        if let existingCell {
            let age = abs(existingCell.dateModified.timeIntervalSinceNow)
            if age < ninetyDaysInSeconds && !existingCell.landmarks.isEmpty {
                return
            }
        }
        
        // cell is stale/nil, so update cell and set landmarks to API ground truth.
        let fetchedLandmarks = try await apiClient.fetchLandmarks(geohash: geohash)
        
        let cell = existingCell ?? MapCell(geohash: geohash)
        cell.dateModified = .now
        backgroundContext.insert(cell)
        
        let fetchedLandmarkIDs = Set(fetchedLandmarks.map { $0.wikidataID })
        for landmark in cell.landmarks where !fetchedLandmarkIDs.contains(landmark.wikidataID) {
            backgroundContext.delete(landmark)
        }
        
        // if the landmark already exists, update instead of create new
        let existingLandmarkMap = Dictionary(uniqueKeysWithValues: cell.landmarks.map{ ($0.wikidataID, $0) })
        for dto in fetchedLandmarks {
            if let existingLandmark = existingLandmarkMap[dto.wikidataID] {
                existingLandmark.update(from: dto)
            } else {
                let landmark = Landmark(from: dto)
                landmark.cell = cell
                backgroundContext.insert(landmark)
            }
        }
            
        try backgroundContext.save()
    }
    
    func synchronizePreferences(from sentence: String) async throws {
        let backgroundContext = ModelContext(self.modelContainer)
        backgroundContext.autosaveEnabled = false
        
        let existingPreferences = try backgroundContext.fetch(FetchDescriptor<LandmarkPreference>())
        let vibeSet = Set(existingPreferences.filter { $0.type == .vibe }.map { $0.value })
        let classificationSet = Set(existingPreferences.filter { $0.type == .classification }.map { $0.value })
        
        print("synchronizePreferences...")
        let fetchedPreferences = try await llmClient.determinePreferences(from: sentence)
        print("preferences received!")
        
        let filteredVibes = fetchedPreferences.vibes.filter { !vibeSet.contains($0) }
        let filteredClassifications = fetchedPreferences.classifications.filter { !classificationSet.contains($0) }
        
        filteredVibes.forEach { backgroundContext.insert(LandmarkPreference(type: .vibe, value: $0)) }
        filteredClassifications.forEach { backgroundContext.insert(LandmarkPreference(type: .classification, value: $0)) }
        
        try backgroundContext.save()
    }
}
 
