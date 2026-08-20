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
        do {
            container = try ModelContainer(for: Visit.self, VibeKeyword.self, Landmark.self)
        } catch {
            fatalError("Failed to configure SwiftData container: \(error)")
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
        MainView()
        
//        if vibes.isEmpty {
//            OnboardingView()
//        } else {
//            
//        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
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
            
            Button("Start Exploring") {
                Task {
                    isProcessing = true
                    await processVibe()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(vibeSentence.isEmpty || isProcessing)
            
            if isProcessing {
                ProgressView()
            }
        }
        .padding()
    }
    
    private func processVibe() async {
        // TODO: Pipe `vibeSentence` to LLM to extract keywords.
        // Mocking the LLM extraction below:
        let extractedKeywords = ["history", "architecture", "coffee"]
        
        for keyword in extractedKeywords {
            context.insert(VibeKeyword(keyword: keyword))
        }
        try? context.save()
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
                    Marker(landmark.title, coordinate: CLLocationCoordinate2D(latitude: landmark.latitude, longitude: landmark.longitude))
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
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
            _ = try? await fetchService.runFetchFlow(at: coordinate)
            isFetching = false
        }
    }
}

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


#Preview {
    let container: ModelContainer = try! ModelContainer(for: Visit.self, VibeKeyword.self, Landmark.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    let storage: StorageProtocol = Storage(modelContext: container.mainContext)
    
    let fetchService: FetchService = FetchService(storage: storage, wikipediaClient: WikipediaClient(), llmClient: LLMClient())
    let locationManager: LocationManager = LocationManager(storage: storage, fetchService: fetchService)
    
    return ContentView()
        .environment(locationManager)
        .environment(fetchService)
        .modelContainer(container)
}

