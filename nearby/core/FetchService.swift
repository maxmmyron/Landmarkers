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
}

@Observable
class FetchService: FetchServiceProtocol {
    private let NINETY_DAYS_AGO: TimeInterval = -60*60*24*90
    
    let modelContainer: ModelContainer
    let apiClient: APIClientProtocol
    
    init(modelContainer: ModelContainer, apiClient: APIClientProtocol) {
        self.modelContainer = modelContainer
        self.apiClient = apiClient
    }
    
    func synchronizeLandmarks(within geohash: String) async throws {
        let backgroundContext = ModelContext(self.modelContainer)
        backgroundContext.autosaveEnabled = false
        
        // cancel fetch if there's a non-stale cell.
        let existingCell = try backgroundContext.fetch(FetchDescriptor<MapCell>(predicate: #Predicate { $0.geohash == geohash })).first
        let isFresh = existingCell?.dateModified.timeIntervalSinceNow ?? -Double.infinity >= NINETY_DAYS_AGO
        if isFresh { return }
        
        // cell is stale/nil, so update cell and set landmarks to API ground truth.
        let fetchedLandmarks = try await apiClient.fetchLandmarks(geohash: geohash)
        
        
        let cellDescriptor = FetchDescriptor(predicate: #Predicate<MapCell> { $0.geohash == geohash })
        let cell = try backgroundContext.fetch(cellDescriptor).first ?? MapCell(geohash: geohash)
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
}
 
