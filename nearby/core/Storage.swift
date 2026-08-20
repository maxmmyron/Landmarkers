//
//  Storage.swift
//  nearby
//
//  Created by Max Myron on 8/13/26.
//

import SwiftData

protocol StorageProtocol: Sendable {
    func getExistingLandmarks() async -> [Landmark]
    func getVibes() async -> [VibeKeyword]
    func getVisits() async -> [Visit]
    func save<T: PersistentModel>(_ models: [T]) async throws
}

@MainActor // Since models are bound to the main thread, this fetch class must be as well
class Storage: StorageProtocol {
    private let modelContext: ModelContext
    
    init (modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getExistingLandmarks() async -> [Landmark] {
        let descriptor = FetchDescriptor<Landmark>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getVibes() async -> [VibeKeyword] {
        let vibeDescriptor = FetchDescriptor<VibeKeyword>()
        return (try? modelContext.fetch(vibeDescriptor)) ?? []
    }
    
    func getVisits() async -> [Visit] {
        let descriptor = FetchDescriptor<Visit>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func save<T: PersistentModel>(_ models: [T]) async throws {
        for model in models {
            modelContext.insert(model)
        }
        try? modelContext.save()
    }
    
    
}
