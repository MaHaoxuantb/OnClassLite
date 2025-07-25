//
//  EventsInCategoryView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData


//MARK: -EventsInCategoryView
struct EventsInCategoryView: View {
    //Received model object
    @Bindable var category: CategoriesModel
    
    //Views
    @State private var showAddEventView = false
    @State private var selectedEvent: Event? = nil
    
    //Model
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            ForEach(category.events) { event in
                Button {
                    selectedEvent = event          // open edit sheet
                } label: {
                    HStack {
                        Circle()
                            .fill(event.color)
                            .frame(width: 10, height: 10)
                        Text(event.name)
                            .font(.headline)
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
        .navigationTitle(Text(category.name))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button {
                    HapticsManager.shared.playHapticFeedback()
                    showAddEventView = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
        .sheet(isPresented: $showAddEventView) {
            AddEventView(category: category)
        }
        .sheet(item: $selectedEvent) { event in
            AddEventView(category: category, event: event)
        }
    }
    
    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { category.events[$0] }
        for event in toDelete {
            modelContext.delete(event)
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete event: \(error)")
        }
    }
}

//MARK: -AddEventView
struct AddEventView : View {
    //Received variables
    
    //World
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var category: CategoriesModel
    /// `nil` when adding a new event; non‑`nil` when editing.
    var event: Event? = nil
    
    //Form variables
    @State private var name: String = ""
    @State private var descriptions: String = ""
    
    @State private var date: Date = Date()
    @State private var isAllDay: Bool = false
    @State private var duration: Int = 60
    
    @State private var needLoop: Bool = false
    @State private var loopDuration: Int = 0 //days
    
    @State private var color: Color = .accentColor
    @State private var details: String = ""
    @State private var tags: [String] = []
    
    @State private var newTag: String = ""
    
    init(category: CategoriesModel, event: Event? = nil) {
        self._category = Bindable(wrappedValue: category)
        self.event = event
        _name         = State(initialValue: event?.name ?? "")
        _descriptions = State(initialValue: event?.descriptions ?? "")
        _date         = State(initialValue: event?.date ?? Date())
        _isAllDay     = State(initialValue: event?.isAllDay ?? false)
        _duration     = State(initialValue: event?.duration ?? 60)
        _needLoop     = State(initialValue: event?.needLoop ?? false)
        _loopDuration = State(initialValue: event?.loopDuration ?? 0)
        _color        = State(initialValue: event?.color ?? .accentColor)
        _details      = State(initialValue: event?.details ?? "")
        _tags         = State(initialValue: event?.tags?.map { $0.name } ?? [])
    }
    
    //View
    let SetEventDurations = [15, 30, 45, 60, 90, 120, 150, 180, 240, 300]
    
    let SetLoopDurations = [1, 2, 3, 7, 14]
    
    //World
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                Spacer()
                    .frame(height: 60)
                VStack {
                    TextField("Event Name", text: $name)
                    Divider()
                    TextField("Event Descriptions*", text: $descriptions)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                )
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                VStack {
                    DatePicker("Event Date", selection: $date)
                    Divider()
                    Toggle(isOn: $isAllDay) {
                        Text("All Day Event")
                    }
                    if !isAllDay {
                        VStack {
                            Divider()
                            HStack {
                                Text("Event Duration")
                                Spacer()
                            }
                            .padding([.top, .leading, .trailing], 1)
                            Picker("Select Duration", selection: $duration) {
                                ForEach(SetEventDurations, id: \.self) { SetEventDuration in
                                    Text("\(SetEventDuration) minutes").tag(SetEventDuration)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: !isAllDay)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                )
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                VStack {
                    Toggle(isOn: $needLoop) {
                        Text("Event need to Repeat")
                    }
                    if needLoop {
                        VStack {
                            Divider()
                            HStack {
                                Text("Event Repeat Duration")
                                Spacer()
                            }
                            .padding([.top, .leading, .trailing], 1)
                            Picker("Select Duration", selection: $loopDuration) {
                                ForEach(SetLoopDurations, id: \.self) { SetLoopDuration in
                                    Text("\(SetLoopDuration) days").tag(SetLoopDuration)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: needLoop)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                )
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                VStack {
                    ColorPicker("Color", selection: $color)
                    Divider()
                    TextField("More Details*", text: $details)
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                )
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                
                VStack {
                    ForEach(tags, id: \.self) {tag in
                        HStack {
                            Button(action: {
                                
                            }) {
                                Image(systemName: "minus.circle.fill")
                            }
                            Text("\(tag)")
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteTag)
                    
                    HStack {
                        Button(action: {
                            addNew()
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        TextField("Add a Tag, then press plus", text: $newTag, onCommit: addNew)
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                )
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            
            // Header Shadow
            VStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .defaultBackground.opacity(1.0), location: 0.0),
                        .init(color: .defaultBackground.opacity(0.52), location: 0.6),
                        .init(color: .defaultBackground.opacity(0.06), location: 0.92),
                        .init(color: .defaultBackground.opacity(0.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
            
            //HEADER
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                        HapticsManager.shared.playHapticFeedback()
                    }) {
                        Image(systemName: "multiply.circle")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                            )
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        saveEvent()
                        HapticsManager.shared.playHapticFeedback()
                    }) {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .frame(width: 26, height: 26)
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                            )
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .navigationTitle(Text(event == nil ? "Add Event" : "Edit Event"))
    }
    
    private func saveEvent() {
        if let editing = event {
            editing.name          = name.isEmpty ? "Untitled" : name
            editing.date          = date
            editing.duration      = duration
            editing.isAllDay      = isAllDay
            editing.needLoop      = needLoop
            editing.loopDuration  = needLoop ? loopDuration : nil
            editing.descriptions  = descriptions.isEmpty ? nil : descriptions
            editing.details       = details.isEmpty ? nil : details
            editing.tags          = tags.map { EventTag(name: $0) }
            editing.color         = color
            do {
                try modelContext.save()
                dismiss()
            } catch {
                print("Failed to save event: \(error)")
            }
        } else {
            let newEvent = Event(
                name: name.isEmpty ? "Untitled" : name,
                eventEnded: false,
                date: date,
                duration: isAllDay ? 0 : duration,
                needLoop: needLoop,
                loopDuration: needLoop ? loopDuration : nil,
                description: descriptions.isEmpty ? nil : descriptions,
                details: details.isEmpty ? nil : details,
                tags: tags.map { EventTag(name: $0) },
                color: color,
                isReminder: false,
                reminderFinished: false,
                parentCategory: category
            )
            newEvent.isAllDay = isAllDay
            category.events.append(newEvent)
            do {
                try modelContext.save()
                dismiss()
            } catch {
                print("Failed to save event: \(error)")
            }
        }
    }

    func deleteTag(at offsets: IndexSet) {
        tags.remove(atOffsets: offsets)
    }

    func addNew() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tags.append(trimmed)
        newTag = ""
    }
}

#Preview {
    let previewCategory = CategoriesModel(name: "Demo", sortIndex: 0, description: nil, details: nil, color: .accentColor)
    AddEventView(category: previewCategory)
        .modelContainer(for: [CategoriesModel.self, Event.self, EventTag.self, EventAlarms.self], inMemory: true)
}
