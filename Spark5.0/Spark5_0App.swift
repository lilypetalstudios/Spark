//
//  Spark5_0App.swift
//  Spark5.0
//
//  Created by sayuri patel on 8/18/24.
//

import SwiftUI
import Firebase

@main
struct Spark5_0App: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


