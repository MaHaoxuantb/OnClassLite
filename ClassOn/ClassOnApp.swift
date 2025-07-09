//
//  ClassOnApp.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import SwiftUI
import SwiftData

@main
struct ClassOnApp: App {
    init() {
        UITextView.appearance().backgroundColor = .clear
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CommonDaysModel.self,
            CategoriesModel.self,
            CommonClass.self,
            Event.self,
            EventAlarms.self,
        ])

        do {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [config])
            } else {
                return try ModelContainer(for: schema)
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }
}
