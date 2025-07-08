//
//  ContentView.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    //App Storage
    @AppStorage("TheFirstTimeUsingApp") var isTheFirstTimeUsingApp: Bool = true
    
    //Models
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommonDaysModel.number) private var CommonDays: [CommonDaysModel]
    
    //State
    @State private var isShowAddCategorySheet: Bool = false
    
    var body: some View {
        TabView {
            EditView()
                .tabItem {
                    Label("Edit", systemImage: "square.and.pencil")
                }
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
        //createDefaultDaysIfNeeded
        .onAppear {
            if isTheFirstTimeUsingApp {
                createDefaultDaysIfNeeded(modelContext: modelContext)
                isTheFirstTimeUsingApp = false
            }
        }
    }
    
    //createDefaultDaysIfNeeded
    private func createDefaultDaysIfNeeded(modelContext: ModelContext) {
        let fetchRequest = FetchDescriptor<CommonDaysModel>()
        let existingDays = try? modelContext.fetch(fetchRequest)

        if existingDays?.count ?? 0 < 7 {
            var counter = 0 //Use counter to assign a number to order it
            for day in SevenDay.allCases {
                let newDay = CommonDaysModel(
                    number: counter,
                    day: day,
                )
                modelContext.insert(newDay)
                counter += 1
            }
            try? modelContext.save()
        }
    }
}

struct HomeView: View {
    var body: some View {
        TabView {
            Text("This is HomeView")
            
        }
    }
}

#Preview {
    // Simulate first launch
    UserDefaults.standard.set(true, forKey: "TheFirstTimeUsingApp")
    return ContentView()
        .modelContainer(for: CommonDaysModel.self, inMemory: true)
}
