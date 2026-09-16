//
//  SearchList.swift
//  nearby
//
//  Created by Max Myron on 9/15/26.
//

import SwiftUI


struct SearchList: View {
    let searchText: String

    var body: some View {
        ScrollView {
            if searchText.isEmpty {
                ContentUnavailableView(
                    "Search Nearby",
                    systemImage: "magnifyingglass",
                    description: Text("Type a location, category, or vibe.")
                )
                .padding(.top, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Result \(index + 1)")
                                .font(.headline)
                            Text("Placeholder search result summary or address detail.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
