//
//  LandmarkersApp.swift
//  nearby
//
//  Created by Max Myron on 5/1/26.
//

import SwiftUI
import MapKit
import SwiftData

@main
struct LandmarkersApp: App {
    let container: ModelContainer
    @State private var fetchService: FetchService
    @State private var locationManager: LocationManager
    
    init() {
        let schema = Schema([Landmark.self, Visit.self, LandmarkPreference.self, MapCell.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("SwiftData storage error: \(error). Falling back to in-memory container.")
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                container = try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Failed to initialize SwiftData container: \(error)")
            }
        }
        
        let fetchService = FetchService(modelContainer: container, apiClient: APIClient(), llmClient: LLMClient())
        self.locationManager = LocationManager(modelContainer: container, fetchService: fetchService)
        self.fetchService = fetchService
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .environment(fetchService)
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    @Query private var preferences: [LandmarkPreference]
    
    var body: some View {
        if preferences.isEmpty {
            OnboardingView()
        } else {
            MainView()
        }
    }
}


enum SheetTab {
    case landmarks
    case profile
    case search
}


//// MARK: - Main Map View
//struct MainMapView: View {
//    @Environment(LocationManager.self) var locationManager
//    @Environment(\.modelContext) private var context
//    @Query private var landmarks: [Landmark]
//    
//    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
//    @State private var isFetching = false
//    
//    @Environment(FetchService.self) private var fetchService
//    
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            Map(position: $cameraPosition) {
//                UserAnnotation()
//                ForEach(landmarks) { landmark in
//                    let coordinate = CLLocationCoordinate2D(
//                        latitude: landmark.latitude,
//                        longitude: landmark.longitude
//                    )
//                    
//                    Marker(landmark.name, coordinate: coordinate)
//                }
//            }
//            .mapControls {
//                Spacer()
//                MapUserLocationButton()
//            }
//            
//            HStack(alignment: .center) {
//                ModeSwitcher()
//                Button {
//                    runFetch(at: CLLocationCoordinate2D(latitude: 37.7775, longitude: -122.416389))
//                } label: {
//                    Text("Do a thing")
//                }
//            }
//                .padding(.bottom, 16)
//            
//            
//        }
//        .onAppear {
//            Task {
//                guard let coord = try? await locationManager.requestImmediateLocation() else { return }
//                runFetch(at: coord)
//            }
//        }
//    }
//    
//    private func scanArea() {
//        // In a full implementation, you would extract the center coordinate from the current Map region.
//        // For simplicity, we fallback to user location here.
//        runFetch(at: locationManager.location)
//    }
//    
//    private func runFetch(at coordinate: CLLocationCoordinate2D) {
//        isFetching = true
//        Task {
//            do {
//                try await fetchService.synchronizeLandmarks(within: coordinate.geohash(length: 6))
//            } catch {
//                print("failed to synch landmarks in view: \(error.localizedDescription)")
//            }
//            isFetching = false
//        }
//    }
//}

struct ModeSwitcher: View {
    @Environment(LocationManager.self) var locationManager
    
    @State var toggled = false {
        didSet {
            locationManager.updateLocationMonitoringMode(mode: toggled ? .live : .ambient)
        }
    }
    
    var body: some View {
        Toggle("Live", isOn: $toggled)
            .frame(maxWidth: 119)
    }
}


// MARK: Preview
@MainActor
struct PreviewContainer {
    static var shared: ModelContainer = {
        let schema = Schema([Landmark.self, Visit.self, LandmarkPreference.self, MapCell.self])
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create preview SwiftData container: \(error.localizedDescription)")
        }
    }()
}

#Preview {
    let container = PreviewContainer.shared
    
    let fetchService = FetchService(modelContainer: container, apiClient: APIClient(), llmClient: LLMClient())
    let locationManager = LocationManager(modelContainer: container, fetchService: fetchService)
    
    // Explicit return is required when declaring variables inside the macro
    return ContentView()
        .environment(locationManager)
        .environment(fetchService)
        .modelContainer(container)
}
