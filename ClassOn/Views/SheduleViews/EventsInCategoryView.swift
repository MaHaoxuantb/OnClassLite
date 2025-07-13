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
    //Received values
    var categoryName: String
    var eventsInCategory: [Event]
    
    //Views
    @State var showAddEventView: Bool = false
    
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
        .sheet(isPresented: $showAddEventView) {
            AddEventView()
        }
    }
}

struct AddEventView : View {
    //Received variables
    
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
    
    //View
    let SetDurations = [15, 30, 45, 60, 90, 120, 150, 180, 240, 300]
    
    var body: some View {
        ScrollView {
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
                            ForEach(SetDurations, id: \.self) { SetDuration in
                                Text("\(SetDuration) minutes").tag(SetDuration)
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
                        Picker("Select Duration", selection: $duration) {
                            ForEach(SetDurations, id: \.self) { SetDuration in
                                Text("\(SetDuration) minutes").tag(SetDuration)
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
        }
        .navigationTitle(Text("Add Event"))
    }
}

#Preview {
    AddEventView()
}
