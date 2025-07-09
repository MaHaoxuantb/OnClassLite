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
                Section(header: Text("Settings")) {
                    NavigationLink {
                        EditTimetableView()
                    } label: {
                        Text("Edit TimeTable")
                    }
                    NavigationLink {
                        EditSubjectListView()
                    } label: {
                        Text("Edit Classes")
                    }
                }
                Section(header: Text("Common Days")) {
                    ForEach(CommonDays) { CommonDay in
                        NavigationLink {
                            ClassInCommonDaysView(commonDay: CommonDay)
                        } label: {
                            Text("\(CommonDay.day)")
                                .font(.headline)
                        }
                    }
                }
                Section(header: Text("Category")) {
                    ForEach(Categories) { Category in
                        NavigationLink {
                            EventsInCategoryView(categoryName: Category.name, eventsInCategory: Category.events)
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

//MARK: -ClassInCommonDaysView
struct ClassInCommonDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var commonDay: CommonDaysModel

    @State private var showAddClassView = false

    var body: some View {
        List {
            ForEach(commonDay.commonClasses) { commonClass in
                NavigationLink {
                    CommonClassDetailView(commonClass: commonClass)
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
            AddCommonClassView(commonDay: commonDay,
                               isPresented: $showAddClassView)
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

//MARK: -AddCommonClassView
struct AddCommonClassView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var commonDay: CommonDaysModel
    @Binding var isPresented: Bool

    @Query(sort: \SubjectModel.name) private var subjects: [SubjectModel]
    @State private var selectedSubject: SubjectModel?
    @State private var selectedPeriodIndex = 0
    @State private var color: Color = .accentColor
    @State private var teacherForClass = ""
    @State private var description = ""
    @State private var details = ""

    var body: some View {
        ScrollView {
            VStack {
                // Header
                HStack {
                    Text("New Class")
                        .font(.headline)
                        .padding()
                    Spacer()
                    Button {
                        guard let subject = selectedSubject else { return }
                        let startMinute = SchoolSchedule.periodStartMinutes[selectedPeriodIndex]
                        let duration = SchoolSchedule.periodDurationMinutes[selectedPeriodIndex]
                        let newClass = CommonClass(
                            name: subject.name,
                            isCommonClass: true,
                            startMinute: startMinute,
                            durationMinutes: duration,
                            description: description.isEmpty ? nil : description,
                            details: details.isEmpty ? nil : details,
                            teacherForClass: teacherForClass.isEmpty ? nil : teacherForClass,
                            teachersForSubject: subject.teachersForSubject,
                            color: color,
                            parentDay: commonDay
                        )
                        commonDay.commonClasses.append(newClass)
                        modelContext.insert(newClass)
                        do { try modelContext.save() } catch {
                            print("Failed to save new class: \(error)")
                        }
                        isPresented = false
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(selectedSubject == nil ? Color.gray.opacity(0.1) : Color.gray)
                            .padding()
                    }
                }

                VStack(spacing: 16) {
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
                    .frame(maxHeight: 150)
                    .onChange(of: selectedSubject) {
                        if let s = selectedSubject {
                            color = s.color
                            teacherForClass = s.teachersForSubject?.first ?? ""
                        }
                    }

                    // Period picker
                    Picker("Period", selection: $selectedPeriodIndex) {
                        ForEach(SchoolSchedule.periodStartMinutes.indices, id: \.self) { i in
                            let t = SchoolSchedule.periodStartMinutes[i]
                            Text("Period \(i+1) – \(String(format: "%02d:%02d", t/60, t%60))")
                                .tag(i)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 150)

                    // Teacher picker
                    let teacherOptions = selectedSubject?.teachersForSubject ?? []
                    Picker("Teacher", selection: $teacherForClass) {
                        ForEach(teacherOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)

                    ColorPicker("Color", selection: $color)
                    TextField("Description", text: $description)
                    TextField("Details", text: $details)
                }
                Spacer()
            }
            .padding()
        }
    }
}

//MARK: -CommonClassDetailView
struct CommonClassDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var commonClass: CommonClass

    @State private var name: String
    @State private var selectedPeriodIndex: Int
    @State private var color: Color
    @State private var teacherForClass: String
    @State private var teachersForSubjectText: String
    @State private var descriptionText: String
    @State private var detailsText: String

    init(commonClass: CommonClass) {
        self.commonClass = commonClass
        _name = State(initialValue: commonClass.name)
        _color = State(initialValue: commonClass.color)
        let idx = SchoolSchedule.periodStartMinutes.firstIndex(of: commonClass.startMinute) ?? 0
        _selectedPeriodIndex = State(initialValue: idx)
        _teacherForClass = State(initialValue: commonClass.teacherForClass ?? "")
        _teachersForSubjectText = State(
            initialValue: commonClass.teachersForSubject?
                .joined(separator: ", ") ?? ""
        )
        _descriptionText = State(initialValue: commonClass.descriptions ?? "")
        _detailsText = State(initialValue: commonClass.details ?? "")
    }

    var body: some View {
        ScrollView {
            VStack {
                // Header
                HStack {
                    Text("Edit Class")
                        .font(.headline)
                        .padding()
                    Spacer()
                    Button {
                        guard !name.isEmpty else { return }

                        // Update model
                        commonClass.name = name
                        commonClass.color = color
                        commonClass.startMinute = SchoolSchedule.periodStartMinutes[selectedPeriodIndex]
                        commonClass.durationMinutes = SchoolSchedule.periodDurationMinutes[selectedPeriodIndex]
                        commonClass.teacherForClass = teacherForClass.isEmpty ? nil : teacherForClass
                        commonClass.teachersForSubject = teachersForSubjectText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        commonClass.descriptions = descriptionText.isEmpty ? nil : descriptionText
                        commonClass.details = detailsText.isEmpty ? nil : detailsText

                        do { try modelContext.save() } catch {
                            print("Failed to save class: \(error)")
                        }
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(name.isEmpty ? Color.gray.opacity(0.1) : Color.gray)
                            .padding()
                    }
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Name", text: $name)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.regularMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 0.2)
                        )

                    Picker("Period", selection: $selectedPeriodIndex) {
                        ForEach(SchoolSchedule.periodStartMinutes.indices, id: \.self) { index in
                            let start = SchoolSchedule.periodStartMinutes[index]
                            let hour = start / 60
                            let minute = start % 60
                            Text("Period \(index + 1) – \(String(format: "%02d:%02d", hour, minute))")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxHeight: 150)

                    ColorPicker("Color", selection: $color)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.regularMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 0.2)
                        )

                    // Allow entering all possible teachers for the subject
                    Text("Teachers for subject")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Enter names, separated by commas", text: $teachersForSubjectText)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.regularMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray, lineWidth: 0.2)
                        )

                    // Picker to choose which teacher actually teaches this class
                    Text("Teacher for this class")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let detailTeachers = teachersForSubjectText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    Picker("Select teacher", selection: $teacherForClass) {
                        ForEach(detailTeachers, id: \.self) { teacher in
                            Text(teacher).tag(teacher)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundStyle(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray, lineWidth: 0.2)
                    )

                    TextField("Description", text: $descriptionText)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.thinMaterial)
                        )

                    TextField("Details", text: $detailsText)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.thinMaterial)
                        )
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle(Text(name))
    }
}

//MARK: -EventsInCategoryView
struct EventsInCategoryView: View {
    var categoryName: String
    var eventsInCategory: [Event]
    
    var body: some View {
        List {
            ForEach(eventsInCategory) { event in
                NavigationLink {
                    Text("day: \(event.name)")
                } label: {
                    Text("\(event.name)")
                        .font(.headline)
                }
            }
        }
        .navigationTitle(Text("\(categoryName)"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button {
                    HapticsManager.shared.playHapticFeedback()
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
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

//MARK: -EditTimetableView
struct EditTimetableView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeriodModel.index) private var periods: [PeriodModel]
    @State private var showAddPeriod = false
    
    var body: some View {
        List {
            ForEach(periods) { period in
                NavigationLink {
                    PeriodDetailView(period: period)
                } label: {
                    HStack {
                        Text("Period \(period.index + 1)")
                            .font(.headline)
                        Spacer()
                        Text(timeString(for: period.startMinute))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deletePeriod)
            .onMove(perform: movePeriod)
        }
        .navigationTitle("Timetable")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            ToolbarItem {
                Button {
                    showAddPeriod.toggle()
                    HapticsManager.shared.playHapticFeedback()
                } label: {
                    Label("Add Period", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPeriod) {
            AddPeriodView(isPresented: $showAddPeriod)
        }
    }
    
    private func deletePeriod(at offsets: IndexSet) {
        withAnimation {
            offsets.map { periods[$0] }.forEach(modelContext.delete)
        }
    }
    private func movePeriod(from source: IndexSet, to destination: Int) {
        var reordered = periods
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, item) in reordered.enumerated() { item.index = idx }
        try? modelContext.save()
    }
    private func timeString(for m: Int) -> String {
        String(format: "%02d:%02d", m / 60, m % 60)
    }
}

//MARK: -AddPeriodView
struct AddPeriodView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @Query private var periods: [PeriodModel]

    @State private var startTime: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(480 * 60)
    @State private var duration = 45

    var body: some View {
        VStack {
            HStack {
                Text("New Period").font(.headline).padding()
                Spacer()
                Button {
                    let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
                    let startMinute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                    let newPeriod = PeriodModel(
                        index: periods.count,
                        startMinute: startMinute,
                        durationMinutes: duration)
                    modelContext.insert(newPeriod)
                    do {
                        try modelContext.save()
                    } catch {
                        print("❌ Failed saving new Subject: \(error)")
                    }
                    isPresented = false
                    HapticsManager.shared.playHapticFeedback()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.gray)
                        .padding()
                }
            }
            Form {
                DatePicker(
                    "Start Time",
                    selection: $startTime,
                    displayedComponents: .hourAndMinute
                )
                Stepper("Duration: \(duration) min",
                        value: $duration,
                        in: 1...180)
            }
            Spacer()
        }
        .padding()
    }
}

//MARK: -PeriodDetailView
struct PeriodDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var period: PeriodModel
    
    var body: some View {
        Form {
            Stepper("Start minute: \(period.startMinute)",
                    value: $period.startMinute,
                    in: 0...1435,
                    step: 5)
            Stepper("Duration: \(period.durationMinutes) min",
                    value: $period.durationMinutes,
                    in: 1...180)
        }
        .navigationTitle("Period \(period.index + 1)")
        .onDisappear { try? modelContext.save() }
    }
}


//MARK: -EditSubjectListView
struct EditSubjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SubjectModel.name) private var subjects: [SubjectModel]
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
                    let newSubject = SubjectModel(
                        name: name,
                        teachersForSubject: teachersText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) },
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
            Form {
                TextField("Name", text: $name)
                TextField("Teachers (comma separated)", text: $teachersText)
                ColorPicker("Color", selection: $color)
            }
            Spacer()
        }
        .padding()
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
                .joined(separator: ", ") ?? "")
    }
    
    var body: some View {
        Form {
            TextField("Name", text: $subject.name)
            TextField("Teachers (comma separated)", text: $teachersText)
                .onChange(of: teachersText) {
                    subject.teachersForSubject = teachersText
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                }
            ColorPicker("Color", selection: $subject.color)
        }
        .navigationTitle(Text(subject.name))
        .onDisappear { try? modelContext.save() }
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
            inMemory: true)
}
