//
//  AddSubjectView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData

//MARK: -EditSubjectListView
struct EditSubjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SubjectModel.orderId) private var subjects: [SubjectModel]
    @State private var showAddSubject = false
    
    var body: some View {
        List {
            ForEach(subjects) { subject in
                NavigationLink {
                    SubjectDetailView(subject: subject)
                } label: {
                    HStack {
                        Circle().fill(subject.color).frame(width: 10, height: 10)
                        Text(subject.name).font(.headline)
                    }
                }
            }
            .onDelete(perform: deleteSubjects)
            .onMove(perform: moveSubjects)
        }
        .navigationTitle(Text("Subjects"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            ToolbarItem {
                Button {
                    showAddSubject.toggle()
                    HapticsManager.shared.playHapticFeedback()
                } label: {
                    Label("Add Subject", systemImage: "plus")
                }
            }
            ToolbarItem {
                Menu {
                    Button {
                        
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan To Add")
                    }
                    Button {
                        
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share by QR Code")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
        }
        .sheet(isPresented: $showAddSubject) {
            AddSubjectView(isPresented: $showAddSubject)
        }
    }
    
    private func deleteSubjects(at offsets: IndexSet) {
        withAnimation {
            for idx in offsets { modelContext.delete(subjects[idx]) }
        }
    }

    private func moveSubjects(at offsets: IndexSet, to destination: Int) {
        // Reorder in-memory array
        var updated = subjects
        updated.move(fromOffsets: offsets, toOffset: destination)
        // Persist new orderId values
        for (index, subject) in updated.enumerated() {
            subject.orderId = index
        }
        // Save changes
        try? modelContext.save()
    }
}

//MARK: -AddSubjectView
struct AddSubjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    
    @State private var name: String = ""
    @State private var teachersText: String = ""
    @State private var color: Color = .accentColor
    
    var body: some View {
        VStack {
            HStack {
                Text("New Subject").font(.headline).padding()
                Spacer()
                Button {
                    guard !name.isEmpty else { return }
                    // Build Teacher entities from entered names
                    let teacherNames = teachersText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    let teacherEntities = teacherNames.map { name in
                        let t = Teacher(name: name)
                        modelContext.insert(t)
                        return t
                    }
                    let newSubject = SubjectModel(
                        name: name,
                        teachersForSubject: teacherEntities,
                        color: color
                    )
                    modelContext.insert(newSubject)
                    try? modelContext.save()
                    isPresented = false
                    HapticsManager.shared.playHapticFeedback()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(name.isEmpty
                             ? Color.gray.opacity(0.1)
                             : Color.gray)
                        .padding()
                }
            }
            .padding()
            Form {
                TextField("Name", text: $name)
                TextField("Teachers (comma separated)", text: $teachersText)
                ColorPicker("Color", selection: $color)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            Form {
                Text("Understand how this works.")
            }
            Spacer()
        }
        .background(Color.gray.opacity(0.1))
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

//MARK: -SubjectDetailView
struct SubjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var subject: SubjectModel
    @State private var teachersText: String

    init(subject: SubjectModel) {
        self.subject = subject
        _teachersText = State(initialValue:
            subject.teachersForSubject?
                .map { $0.name }
                .joined(separator: ", ") ?? "")
    }

    var body: some View {
        Form {
            TextField("Name", text: $subject.name)
            TextField("Teachers (comma separated)", text: $teachersText)
                .onChange(of: teachersText) {
                    let names = teachersText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    let teacherEntities = names.map { name in
                        let t = Teacher(name: name)
                        modelContext.insert(t)
                        return t
                    }
                    subject.teachersForSubject = teacherEntities
                }
            ColorPicker("Color", selection: $subject.color)
        }
        .navigationTitle(Text(subject.name))
        .onDisappear { try? modelContext.save() }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}
