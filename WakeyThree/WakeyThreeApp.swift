//
//  WakeyThreeApp.swift
//  WakeyThree
//
//  Created by Nico Sendan on 6/5/26.
//

import SwiftUI
import SwiftData

@main
struct WakeyThreeApp: App {
    let sharedModelContainer = WakeyDataStore.shared.container

    var body: some Scene {
        #if os(macOS)
        WindowGroup(id: SettingsView.viewID) {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
        .windowResizability(.contentSize)

        MenuBarExtra("WakeyThree", systemImage: "powersleep") {
            StatusMenuView()
                .modelContainer(sharedModelContainer)
        }
        #else
        WindowGroup {
            PhoneView()
                .modelContainer(sharedModelContainer)
        }
        #endif
    }
}
