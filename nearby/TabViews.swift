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
                            Text(landmark.title)
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
    var body: some View {
        VStack {
            HStack {
                Text("My Story")
                    .font(.largeTitle.bold())
                
                Spacer(minLength: 0)
                
                Button {
                    
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
