//
//  twodoappApp.swift
//  twodoapp
//
//  Created by Suwijak Thanawiboon on 28/9/2568 BE.
//

import SwiftUI

@main
struct twodoappApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    _ = await LocalNotificationManager.shared.requestAuthorization()
                }
        }
    }
}
