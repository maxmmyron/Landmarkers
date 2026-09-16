//
//  BottomView.swift
//  nearby
//
//  Created by Max Myron on 9/15/26.
//

import SwiftUI

struct BottomSheetContent: View {
    @Binding var selectedDetent: PresentationDetent
    @Binding var activeTab: SheetTab
    @Binding var searchText: String
    @FocusState var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Floating Header / Action Bar
            HStack(spacing: 8) {
                if activeTab == .search && selectedDetent == .large {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search landmarks...", text: $searchText)
                            .focused($isSearchFocused)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Button {
                        activeTab = .landmarks
                        selectedDetent = .medium
                    } label: {
                        Label("Landmarks", systemImage: "mappin.and.ellipse")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(activeTab == .landmarks && selectedDetent != .fraction(0.1) ? .accentColor : .secondary.opacity(0.2))

                    Button {
                        activeTab = .profile
                        selectedDetent = .medium
                    } label: {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(activeTab == .profile && selectedDetent != .fraction(0.1) ? .accentColor : .secondary.opacity(0.2))

                    Spacer()

                    Button {
                        activeTab = .search
                        selectedDetent = .medium
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Sheet Body Content
            if selectedDetent != .fraction(0.1) {
                Group {
                    switch activeTab {
                    case .landmarks:
                        LandmarksList()
                    case .profile:
                        ProfileView()
                    case .search:
                        SearchList(searchText: searchText)
                    }
                }
                .transition(.opacity)
            }
        }
        .onChange(of: selectedDetent) { _, newDetent in
            if newDetent == .fraction(0.1) {
                isSearchFocused = false
            }
        }
    }
    

}

