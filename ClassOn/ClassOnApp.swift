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
            SubjectModel.self,
            PeriodModel.self,
            Event.self,
            EventAlarms.self,
            Teacher.self,
            ClassTag.self,
            EventTag.self,
        ])

        do {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [config])
            } else {
                return try ModelContainer(for: schema)
            }
        } catch {
            // Fallback to an in-memory ModelContainer on failure
            print("ModelContainer creation error: \(error)")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                // If fallback also fails, log and abort
                fatalError("Fallback ModelContainer creation also failed: \(error)")
            }
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
