//
//  ProfileView.swift
//  nearby
//
//  Created by Max Myron on 9/15/26.
//

import SwiftUI
import SwiftData

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
                    do {
                        try context.delete(model: Landmark.self)
                    } catch {
                        
                    }
                    
                    do {
                        try context.save()
                    } catch {
                        
                    }
                }
                print("Deletion successful")
            } label: {
                Text("Delete Landmarks")
            }
            
            Button(role: .destructive) {
                Task {
                    do {
                        try context.delete(model: LandmarkPreference.self)
                    } catch {
                        
                    }
                    
                    do {
                        try context.save()
                    } catch {
                        
                    }
                }
                print("Deletion successful")
            } label: {
                Text("Delete Vibes")
            }
        }
    }
}
