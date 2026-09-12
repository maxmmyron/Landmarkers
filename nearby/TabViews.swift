//
//  TabViews.swift
//  nearby
//
//  Created by Max Myron on 8/24/26.
//

import SwiftUI
import SwiftData

struct LandmarksView: View {
    @Query private var landmarks: [Landmark]
    
    var body: some View {
        VStack {
            HStack {
                Text("Landmarks")
                    .font(.largeTitle.bold())
                
                Spacer(minLength: 0)
            }
            .padding(.top, 15)
            .padding(.leading, 10)
            
            List {
                ForEach(landmarks) { landmark in
                    HStack {
                        VStack {
                            Text(landmark.name)
                            Text(landmark.summary)
                        }
                    }
                }
            }
        }
        .padding(15)
    }
}

struct VisitsView: View {
    @Query private var visits: [Visit]
    
    var body: some View {
        VStack {
            HStack {
                Text("Visits")
                    .font(.largeTitle.bold())
                
                Spacer(minLength: 0)
            }
            .padding(.top, 15)
            .padding(.leading, 10)
            
            List {
                ForEach(visits) { visit in
                    HStack {
                        VStack {
                            Text("\(visit.latitude) \(visit.longitude)")
                        }
                    }
                }

            }
        }
        .padding(15)
    }
}


struct ProfileView: View {
    @Query var landmarks: [Landmark]
    
    @Environment(\.modelContext) private var context
    
    @State var isSheetPresented = false
    
    var body: some View {
        VStack {
            HStack {
                Text("My Story")
                    .font(.largeTitle.bold())
                
                Spacer(minLength: 0)
                
                Button {
                    isSheetPresented = true
                } label: {
                    Image(systemName: "gear")
                }
                .padding()
                .frame(width: 40, height: 40)
                .background(.thinMaterial)
                .clipShape(.capsule)
            }
            .padding(.top, 15)
            .padding(.leading, 10)
        }
        .padding(15)
        .sheet(isPresented: $isSheetPresented) {
            Text("Settings")
                .font(.title)
            
            Button(role: .destructive) {
                Task {
                    try context.delete(model: Landmark.self)
                    try context.save()
                }
                print("Deletion successful")
            } label: {
                Text("Delete Landmarks")
            }
            
            Button(role: .destructive) {
                Task {
                    try context.delete(model: LandmarkPreference.self)
                    try context.save()
                }
                print("Deletion successful")
            } label: {
                Text("Delete Vibes")
            }
        }
    }
}

enum TabChoice: String, CaseIterable {
    case landmarks = "Detours"
    case visits = "Visits"
    case profile = "My Story"
    
    var symbolImage: String {
        switch self {
        case .landmarks: return "lizard"
        case .visits: return "target"
        case .profile: return "fleuron"
        }
    }
    
    @ViewBuilder
    func SheetView() -> some View {
        switch self {
        case .landmarks:
            LandmarksView()
        case .visits:
            VisitsView()
        case .profile:
            ProfileView()
        }
    }
}
