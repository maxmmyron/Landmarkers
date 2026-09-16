//
//  LandmarksList.swift
//  nearby
//
//  Created by Max Myron on 9/15/26.
//

import SwiftUI
import SwiftData

struct LandmarksList: View {
    @Environment(LocationManager.self) private var locationManager
    @Query private var landmarks: [Landmark]
    
    var body: some View {
        let filteredLandmarks = landmarks.filter { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude).distance(from: locationManager.location) <= 30000 }
        
        let sortedLandmarks = filteredLandmarks.sorted { a, b in
            CLLocationCoordinate2D(latitude: a.latitude, longitude: a.longitude).distance(from: locationManager.location)
            < CLLocationCoordinate2D(latitude: b.latitude, longitude: b.longitude).distance(from: locationManager.location)
        }
        
        ScrollView() {
            HStack() {
                Text("Landmarks")
                    .font(.largeTitle.bold())
                    .padding(.top, 15)
                    .padding(.leading, 10)
                    .padding(.bottom, 16)
                
                Spacer()
            }
            
            if landmarks.count == 0 {
                VStack {
                    Text("No Landmarks nearby!")
                }
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedLandmarks) { landmark in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(landmark.name)
                                .font(.headline)
                            Text(landmark.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .backgroundStyle(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding(15)
        
    }
}
