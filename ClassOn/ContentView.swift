//
//  ContentView.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import SwiftUI
import SwiftData

enum Tab: Hashable {
    case home, edit, settings
}

struct ContentView: View {
    //App Storage
    @AppStorage("oneWeekStartWith") var oneWeekStartWith: Int = 0 //start with monday(0) by default
    
    //Models
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommonDaysModel.number) private var CommonDays: [CommonDaysModel]
    
    //State
    @State private var selectedTab: Tab = .home
    @State private var isShowAddCategorySheet: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            EditView()
                .modelContainer(
                    for: [
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
                    ]
                )
                .tag(Tab.edit)
                .tabItem {
                    Label("Edit", systemImage: "square.and.pencil")
                }
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onChange(of: selectedTab) {
            HapticsManager.shared.playHapticFeedback()
        }
        //createDefaultDaysIfNeeded
        .onAppear {
            if CommonDays.count < 7 {
                createDefaultDaysIfNeeded(modelContext: modelContext)
            }
        }
    }
    
    //createDefaultDaysIfNeeded
    private func createDefaultDaysIfNeeded(modelContext: ModelContext) {
        let fetchRequest = FetchDescriptor<CommonDaysModel>()
        let existingDays = try? modelContext.fetch(fetchRequest)

        if existingDays?.count ?? 0 < 7 {
            var counter = 0 //Use counter to assign a number to order it
            print("Start creating 7 days")
            if oneWeekStartWith == 0 { //Start Monday
                for day in SevenDay.allCases {
                    // Determine common day flag based on index
                    let newDay: CommonDaysModel
                    if counter == 5 || counter == 6 {   //if not common day
                        newDay = CommonDaysModel(number: counter, day: day, isCommonDay: false)
                    } else {
                        newDay = CommonDaysModel(number: counter, day: day, isCommonDay: true)
                    }
                    modelContext.insert(newDay)
                    counter += 1
                }
            } else if oneWeekStartWith == 6 {
                for day in SevenDay.allCases {
                    // Determine common day flag based on index
                    let newDay: CommonDaysModel
                    if counter == 4 || counter == 5 {   //if not common day
                        newDay = CommonDaysModel(number: counter, day: day, isCommonDay: false)
                    } else {
                        newDay = CommonDaysModel(number: counter, day: day, isCommonDay: true)
                    }
                    modelContext.insert(newDay)
                    counter += 1
                }
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
        .modelContainer(for: CommonDaysModel.self)
}
