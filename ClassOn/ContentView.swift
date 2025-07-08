//
//  ContentView.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var CommonDays: [CommonDaysModel]
    @Query private var Categories: [CategoriesModel]

    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Common Days")) {
                    ForEach(CommonDays) { CommonDay in
                        NavigationLink {
                            Text("Item at \(CommonDay.day)")
                        } label: {
                            Text("\(CommonDay.day)")
                        }
                    }
                }
                Section(header: Text("Category")) {
                    ForEach(Categories) { Category in
                        NavigationLink {
                            Text("Item at \(Category.name)")
                        } label: {
                            Text("\(Category.name)")
                        }
                    }
                    .onDelete(perform: deleteCategory)
                }
            }
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
            /*
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
             */
        } detail: {
            Text("Select an item")
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

#Preview {
    ContentView()
        .modelContainer(for: [CommonDaysModel.self, CategoriesModel.self], inMemory: true)
}
