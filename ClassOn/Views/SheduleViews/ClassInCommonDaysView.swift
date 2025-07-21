//
//  ClassInCommonDaysView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData

//MARK: -ClassInCommonDaysView
struct ClassInCommonDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var commonDay: CommonDaysModel
    
    @State private var showAddClassView = false
    
    var body: some View {
        List {
            ForEach(commonDay.commonClasses) { commonClass in
                NavigationLink {
                    CommonClassFormView(commonDay: $commonDay, commonClass: .constant(commonClass), isPresented: .constant(true))
                } label: {
                    HStack {
                        Circle()
                            .fill(commonClass.color)
                            .frame(width: 10, height: 10)
                        Text(commonClass.name)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%02d:%02d",
                                    commonClass.startMinute / 60,
                                    commonClass.startMinute % 60))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                //Card-Like style
                .listRowSeparator(.hidden)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .background(.clear)
                        .foregroundStyle(.regularMaterial)
                        .padding(
                            EdgeInsets(
                                top: 2,
                                leading: 10,
                                bottom: 2,
                                trailing: 10
                            )
                        )
                )
            }
            .onDelete(perform: delete)
        }
        .navigationTitle(Text("\(commonDay.day.rawValue)"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button {
                    showAddClassView.toggle()
                    HapticsManager.shared.playHapticFeedback()
                } label: {
                    Label("Add Class", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddClassView) {
            CommonClassFormView(commonDay: $commonDay, commonClass: .constant(nil), isPresented: $showAddClassView)
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
    
    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { commonDay.commonClasses[$0] }
        for commonClass in toDelete {
            modelContext.delete(commonClass)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete class: \(error)")
        }
    }
}

// Shared form for adding or editing a CommonClass
struct CommonClassFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var commonDay: CommonDaysModel
    @Binding var commonClass: CommonClass?
    @Binding var isPresented: Bool

    @Query(sort: \SubjectModel.name) private var subjects: [SubjectModel]
    @Query(sort: \PeriodModel.index) private var periodModels: [PeriodModel]
    @State private var name: String = ""
    @State private var selectedSubject: SubjectModel?
    @State private var selectedPeriod: PeriodModel?
    @State private var color: Color = .accentColor
    @State private var teacherForClass: Teacher?
    @State private var descriptionText = ""
    @State private var detailsText = ""

    var isEditing: Bool { commonClass != nil }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(isEditing ? "Edit Class" : "New Class")
                        .font(.headline)
                        .padding()
                    Spacer()
                    Button {
                        guard let subject = selectedSubject,
                              let period = selectedPeriod else { return }
                        let startMinute = period.startMinute
                        let duration = period.durationMinutes

                        let teacherEntities = subject.teachersForSubject
                        let selectedTeacher = teacherForClass

                        if let editing = commonClass {
                            // Update existing
                            editing.name = name
                            editing.color = color
                            editing.startMinute = startMinute
                            editing.durationMinutes = duration
                            editing.descriptions = descriptionText.isEmpty ? nil : descriptionText
                            editing.details = detailsText.isEmpty ? nil : detailsText
                            editing.teachersForSubject = teacherEntities
                            editing.teacherForClass = selectedTeacher
                        } else {
                            // Create new
                            let newClass = CommonClass(
                                name: subject.name,
                                isCommonClass: true,
                                startMinute: startMinute,
                                durationMinutes: duration,
                                description: descriptionText.isEmpty ? nil : descriptionText,
                                details: detailsText.isEmpty ? nil : detailsText,
                                teacherForClass: selectedTeacher,
                                teachersForSubject: teacherEntities,
                                tags: nil,
                                color: color,
                                parentDay: commonDay
                            )
                            commonDay.commonClasses.append(newClass)
                            modelContext.insert(newClass)
                        }
                        do { try modelContext.save() } catch {
                            print("Failed to save class: \(error)")
                        }
                        isPresented = false
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle((selectedSubject == nil) ? Color.gray.opacity(0.1) : Color.gray)
                            .padding()
                    }
                }
                VStack(spacing: 16) {
                    // Initialize state on appear
                    // Subject picker
                    Picker("Subject", selection: $selectedSubject) {
                        ForEach(subjects) { subject in
                            HStack {
                                Circle().fill(subject.color).frame(width: 10, height: 10)
                                Text(subject.name)
                            }
                            .tag(Optional(subject))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
                    .onChange(of: selectedSubject) { s in
                        if let s = s {
                            color = s.color
                            teacherForClass = s.teachersForSubject.first
                        }
                    }

                    // Period picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(periodModels) { period in
                            Text("Period \(period.index + 1) – \(String(format: "%02d:%02d", period.startMinute/60, period.startMinute%60))")
                                .tag(Optional(period))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))

                    // Teacher picker
                    Picker("Teacher", selection: $teacherForClass) {
                        ForEach(selectedSubject?.teachersForSubject ?? [], id: \.id) { teacher in
                            Text(teacher.name).tag(Optional(teacher))
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))

                    ColorPicker("Color", selection: $color)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))

                    VStack(alignment: .leading) {
                        Text("optional").font(.caption)
                        TextField("Description", text: $descriptionText)
                        TextField("Details", text: $detailsText)
                    }
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
                }
                Spacer()
            }
            .padding()
            .onAppear {
                if isEditing, let editing = commonClass {
                    name = editing.name
                    color = editing.color
                    selectedPeriod = periodModels.first(where: { $0.startMinute == editing.startMinute })
                    selectedSubject = subjects.first(where: { $0.id == editing.teachersForSubject?.first?.id })
                    teacherForClass = editing.teacherForClass
                    descriptionText = editing.descriptions ?? ""
                    detailsText = editing.details ?? ""
                } else {
                    selectedSubject = subjects.first
                    selectedPeriod = periodModels.first
                    if let first = selectedSubject {
                        color = first.color
                        teacherForClass = first.teachersForSubject.first
                    }
                }
            }
        }
    }
}
