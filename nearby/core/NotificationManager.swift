//
//  NotificationManager.swift
//  nearby
//
//  Created by Max Myron on 5/1/26.
//

import UserNotifications

class NotificationManager {
    
    init() {
        requestPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendLandmarkAlert(for landmark: Landmark) {
        let content = UNMutableNotificationContent()
        content.title = "Notable Place Nearby"
        content.body = "You're near \(landmark.title). Tap to learn about its history."
        content.sound = .default
        content.userInfo = ["LANDMARK_ID": landmark.id]
        
        let request = UNNotificationRequest(
            identifier: String(landmark.pageid),    // update existing notification if not cleared. prevents screen clutter
            content: content,
            trigger: nil                // fires notification immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
