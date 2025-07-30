//
//  ContentView.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import SwiftUI
import SwiftData

//MARK: -EditView
struct EditView: View {
    //App Storage
    
    //Models
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommonDaysModel.number) private var CommonDays: [CommonDaysModel]
    @Query(sort: \CategoriesModel.sortIndex) private var Categories: [CategoriesModel]
    
    //State of Views
    @State private var ShowAddCategoryView: Bool = false
    
    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Common Classes")) {
                    ForEach(CommonDays) { CommonDay in
                        NavigationLink {
                            ClassInCommonDaysView(commonDay: CommonDay)
                        } label: {
                            Text("\(CommonDay.day)")
                                .font(.headline)
                        }
                    }
                }
                Section(header: Text("Category of Events")) {
                    ForEach(Categories) { Category in
                        NavigationLink {
                            EventsInCategoryView(category: Category)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Category.color)
                                    .frame(width: 10, height: 10)
                                Text(Category.name)
                                    .font(.headline)
                            }
                        }
                    }
                    .onMove(perform: moveItems)
                    .onDelete(perform: deleteCategory)
                }
            }
            .navigationTitle(Text("Shedule"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        ShowAddCategoryView.toggle()
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
        } content: {
            Text("Choose one day or category first")
        } detail: {
            Text("Select an event first")
        }
        .sheet(isPresented: $ShowAddCategoryView) {
            AddCategoryView(ViewIsPresent: $ShowAddCategoryView)
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }

    private func deleteCategory(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(Categories[index])
            }
        }
    }
    
    func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = Categories
          revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in revisedItems.enumerated() {
            item.sortIndex = index
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save category order: (error)")
        }
    }
}


//MARK: -AddCategoryView
struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var details: String = ""
    @State private var color: Color = .blue
    
    @Binding var ViewIsPresent: Bool
    @Query private var Categories: [CategoriesModel]
    
    var body: some View {
        VStack {
            //Header
            HStack {
                Text("New Category")
                    .font(.headline)
                    .padding()
                Spacer()
                Button() {
                    if !name.isEmpty {
                        let newIndex = Categories.count
                        let newCategory = CategoriesModel(
                            name: name,
                            sortIndex: newIndex,
                            description: description,
                            details: details,
                            color: color
                        )
                        modelContext.insert(newCategory)
                        ViewIsPresent = false
                        HapticsManager.shared.playHapticFeedback()
                    }
                } label : {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(name.isEmpty ? Color.gray.opacity(0.1) : Color.gray)
                        .padding()
                }
            }
            //Form
            VStack {
                VStack {
                    TextField("Name", text: $name)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.regularMaterial)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 0.2))
                    ColorPicker("Color", selection: $color)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.regularMaterial)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 0.2))
                }
                .padding(.vertical)
                VStack(alignment: .leading) {
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    TextField("Description", text: $description)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.thinMaterial)
                        )
                    TextField("Details", text: $details)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.thinMaterial)
                        )
                }
                .padding(.vertical)
            }
            .padding()
            Spacer()
        }
    }
}


#Preview {
    EditView()
        .modelContainer(
            for: [CommonDaysModel.self,
                  CategoriesModel.self,
                  CommonClass.self,
                  SubjectModel.self,
                  PeriodModel.self],
        )
}
