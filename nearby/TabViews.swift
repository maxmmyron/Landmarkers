//
//  TabViews.swift
//  nearby
//
//  Created by Max Myron on 8/24/26.
//

import SwiftUI
import SwiftData


enum TabChoice: String, CaseIterable {
    case landmarks = "Detours"
//    case visits = "Visits"
    case profile = "My Story"
    
    var symbolImage: String {
        switch self {
        case .landmarks: return "lizard"
//        case .visits: return "target"
        case .profile: return "fleuron"
        }
    }
}
