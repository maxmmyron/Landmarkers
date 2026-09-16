//
//  MainView.swift
//  nearby
//
//  Created by Max Myron on 9/15/26.
//

import SwiftUI
import MapKit
import SwiftData

struct MainView: View {
    @State private var opacity = 0.0
    @Query private var landmarks: [Landmark]
    @Environment(\.modelContext) private var context
    @Environment(LocationManager.self) private var locationManager
    
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedDetent: PresentationDetent = .fraction(0.1)
    @State private var activeTab: SheetTab = .landmarks
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        
        
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(landmarks) { landmark in
                Marker(landmark.name, coordinate: CLLocationCoordinate2D(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                ))
            }
        }
        .mapControls {
            MapUserLocationButton()
        }
        .sheet(isPresented: .constant(true)) {
            BottomSheetContent(
                selectedDetent: $selectedDetent,
                activeTab: $activeTab,
                searchText: $searchText,
                isSearchFocused: _isSearchFocused
            )
            .presentationDetents([.fraction(0.1), .medium, .large], selection: $selectedDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
            .presentationCornerRadius(24)
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
