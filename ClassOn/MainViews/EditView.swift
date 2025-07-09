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
    @State private var ShowAddCategoryView: Bool = false
    
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
                }
                Section(header: Text("Category")) {
                    ForEach(Categories) { Category in
                        NavigationLink {
                            Text("Item at \(Category.name)")
                        } label: {
                            Text("\(Category.name)")
                                .font(.headline)
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
                    Button {
                        ShowAddCategoryView.toggle()
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
            AddCategoryView()
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
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var NameFilled: Bool = false
    @State private var description: String? = nil
    @State private var details: String? = nil
    @State private var color: Color = .blue
    
    var body: some View {
        VStack {
            //Header
            HStack {
                Text("New Category")
                    .font(.headline)
                    .padding()
                Spacer()
                Button() {
                    let newCategory = CategoriesModel(
                        name: name,
                        description: description,
                        details: details,
                        color: color
                    )
                    modelContext.insert(newCategory)
                } label : {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(NameFilled ? Color.gray : Color.gray.opacity(0.2))
                        .padding()
                }
            }
            //Form
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                Section {
                    TextField("Description", text: Binding($description, replacingNilWith: ""))
                    TextField("Details", text: Binding($details, replacingNilWith: ""))
                }
                Section {
                    ColorPicker("Color", selection: $color)
                }
            }
            .onChange(of: name) {
                if name != "" {
                    NameFilled = true
                }
            }
        }
    }
}

// A helper to bridge optional String to a non-optional Binding:
extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith placeholder: String) {
        self.init(
            get: { source.wrappedValue ?? placeholder },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    EditView()
        .modelContainer(for: [CommonDaysModel.self, CategoriesModel.self, CommonClass.self], inMemory: true)
}
