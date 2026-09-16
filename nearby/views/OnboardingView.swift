//
//  OnboardingView.swift
//  nearby
//
//  Created by Max Myron on 9/15/26.
//

import SwiftUI
import SwiftData


struct OnboardingView: View {
    @Environment(FetchService.self) private var fetchService
    @Environment(\.modelContext) private var context
    
    @State private var vibeSentence = ""
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your vibe?")
                .font(.largeTitle)
                .bold()
            
            Text("Describe what kind of places you want to discover around you.")
                .foregroundStyle(.secondary)
            
            TextField("e.g. I love historic architecture and quiet cafes", text: $vibeSentence)
                .textFieldStyle(.roundedBorder)
                .padding()
//                .onChange(of: vibeSentence) { _, new in
//                    let words = new.split(separator: " ")
//                    if words.count > 25 {
//                        // Rejoin the allowed number of words with a space
//                        vibeSentence = words.prefix(25).joined(separator: " ")
//                    }
//                }
            
            Button("Start Exploring") {
                Task {
                    isProcessing = true
                    do {
                        try await fetchService.synchronizePreferences(from: vibeSentence)
                    } catch {
                        print("Failed to synchronizeVibes: \(error.localizedDescription)")
                    }
                    isProcessing = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vibeSentence.isEmpty || isProcessing)
            
            Button("Test") {
                Task {
                    print("fetching vibes...")
                    isProcessing = true
                    do {
                        try await fetchService.synchronizePreferences(from: "Looking for a grungy, low-key spot with live indie music, craft beer, and a hidden patio or rooftop where it doesn't feel super commercialized.")
                        
                    } catch {
                        print("Failed to synchronize preferences with storage \(error.localizedDescription)")
                    }
                    isProcessing = false
                }
            }
            
            if isProcessing {
                ProgressView()
            }
        }
        .padding()
    }
}
