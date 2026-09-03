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
        let schema = Schema([Landmark.self, Visit.self, VibeKeyword.self])
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
        
        let storage = Storage(modelContext: container.mainContext)
        let fetchService = FetchService(storage: storage, wikipediaClient: WikipediaClient(), llmClient: LLMClient())
        
        self.locationManager = LocationManager(storage: storage, fetchService: fetchService)
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
    @Query private var vibes: [VibeKeyword]
    
    var body: some View {
        if vibes.isEmpty {
            OnboardingView()
        } else {
            MainView()
        }
    }
}

// MARK: - Onboarding View
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
                    _ = try? await fetchService.fetchAndStoreVibes(from: vibeSentence)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vibeSentence.isEmpty || isProcessing)
            
            Button("Test") {
                Task {
                    print("fetching vibes...")
                    isProcessing = true
                    _ = try? await fetchService.fetchAndStoreVibes(from: "Hello world test")
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

struct MainView: View {
//    @State private var selectedTab: TabChoice = .landmarks
    
    @State private var opacity = 0.0
    
    var body: some View {
        SplitView(bottomViewOpacity: $opacity) {
            MainMapView()
        } bottom: {
            TabView {
                ForEach(TabChoice.allCases, id: \.rawValue) { tabChoice in
                    Tab(tabChoice.rawValue, systemImage: tabChoice.symbolImage) {
                        ScrollView(.vertical) {
                            tabChoice.SheetView()
                        }
                        .toolbarBackground(.visible, for: .tabBar)
                        .opacity(opacity)
                    }
                }
            }       
        }
    }
    
    @ViewBuilder
    func ScanButton() -> some View {
        Button {} label: {
            Image(systemName: "fleuron")
        }
        .font(.title3)
        .padding()
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - Main Map View
struct MainMapView: View {
    @Environment(LocationManager.self) var locationManager
    @Environment(\.modelContext) private var context
    @Query private var landmarks: [Landmark]
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isFetching = false
    
    @Environment(FetchService.self) private var fetchService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(landmarks) { landmark in
                    let coordinate = CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(landmark.latitude),
                        longitude: CLLocationDegrees(landmark.longitude)
                    )
                    
                    Marker(landmark.title, coordinate: coordinate)
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            
            HStack(alignment: .center) {
                ModeSwitcher()
                Button {
                    Task {
                        try? await locationManager.fetchService.wikipediaClient.fetchLandmarks(at: CLLocationCoordinate2D(latitude: 37.7775, longitude: -122.416389))
                    }
                    
                } label: {
                    Text("Do a thing")
                }
            }
                .padding(.bottom, 16)
            
            
        }
        .onAppear {
            Task {
                guard let coord = try? await locationManager.requestImmediateLocation() else { return }
                runFetch(at: coord)
            }
        }
    }
    
    private func scanArea() {
        // In a full implementation, you would extract the center coordinate from the current Map region.
        // For simplicity, we fallback to user location here.
        guard let center = locationManager.location else { return }
        runFetch(at: center)
    }
    
    private func runFetch(at coordinate: CLLocationCoordinate2D) {
        isFetching = true
        Task {
            _ = try? await fetchService.fetchAndStoreNewLandmarks(at: coordinate)
            isFetching = false
        }
    }
}

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
        let schema = Schema([ Visit.self, VibeKeyword.self, Landmark.self ])
        
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
    
    // Initialize your dependencies using the preview container's main context
    let storage = Storage(modelContext: container.mainContext)
    let fetchService = FetchService(
        storage: storage,
        wikipediaClient: WikipediaClient(),
        llmClient: LLMClient()
    )
    let locationManager = LocationManager(
        storage: storage,
        fetchService: fetchService
    )
    
    // Explicit return is required when declaring variables inside the macro
    return ContentView()
        .environment(locationManager)
        .environment(fetchService)
        .modelContainer(container)
}
