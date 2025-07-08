//
//  ContentView.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import SwiftUI
import SwiftData

struct EditView: View {
    //App Storage
    
    //Models
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommonDaysModel.number) private var CommonDays: [CommonDaysModel]
    @Query private var Categories: [CategoriesModel]
    
    //State
    
    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Common Days")) {
                    ForEach(CommonDays) { CommonDay in
                        NavigationLink {
                            ClassInCommonDaysView(day: "\(CommonDay.day)", commonDayClass: CommonDay.commonClasses)
                        } label: {
                            Text("\(CommonDay.day)")
                                .font(.headline)
                        }
                    }
                    // 2. hide the separator line:
                    .listRowSeparator(.hidden)
                    // 3. clear out any background:
                    .listRowBackground(Color.clear)
                }
                Section(header: Text("Category")) {
                    ForEach(Categories) { Category in
                        NavigationLink {
                            Text("Item at \(Category.name)")
                        } label: {
                            Text("\(Category.name)")
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .onDelete(perform: deleteCategory)
                }
            }
            .navigationTitle(Text("ClassOn"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addCategory) {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
        } content: {
            Text("Choose one day or category first")
        } detail: {
            Text("Select an event first")
        }
    }
    
    private func addCategory() {
        withAnimation {
            let newItem = CategoriesModel(name: "New Category")
            modelContext.insert(newItem)
        }
    }

    private func deleteCategory(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(Categories[index])
            }
        }
    }
}

//MARK: -ClassInCommonDaysView
struct ClassInCommonDaysView: View {
    var day: String = ""
    var commonDayClass: [CommonClass]
    
    var body: some View {
        List {
            
        }
        .navigationTitle(Text("\(day)"))
    }
}

#Preview {
    EditView()
        .modelContainer(for: [CommonDaysModel.self, CategoriesModel.self, CommonClass.self], inMemory: true)
}
