//
//  EditTimetableView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData


//MARK: -EditTimetableView
struct EditTimetableView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeriodModel.index) private var periods: [PeriodModel]
    @State private var showExpandedTools: Bool = false
    @State private var selectedPeriod: PeriodModel?
    @State private var isShowingPeriodEditor: Bool = false
    
    var body: some View {
        List {
            ForEach(periods) { period in
                Button {
                    selectedPeriod = period
                    isShowingPeriodEditor = true
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
            ToolbarItem {
                Menu {
                    // Manually adding
                    Button {
                        selectedPeriod = nil
                        isShowingPeriodEditor = true
                    } label: {
                        Image(systemName: "plus")
                        Text("Add Period")
                    }
                    
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
                    
                    EditButton()
                } label: {
                    Label("More", systemImage: "ellipsis.circle.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
        }
        .sheet(isPresented: $isShowingPeriodEditor) {
            AddPeriodView(isPresented: $isShowingPeriodEditor, periodToEdit: selectedPeriod)
                .id(selectedPeriod?.id ?? UUID())
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
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
    private let durationOptions = Array(stride(from: 25, through: 120, by: 5))
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    var periodToEdit: PeriodModel?
    @Query private var periods: [PeriodModel]
    @State private var startTime: Date
    @State private var duration: Int
    
    init(isPresented: Binding<Bool>, periodToEdit: PeriodModel? = nil) {
        self._isPresented = isPresented
        self.periodToEdit = periodToEdit
        if let p = periodToEdit {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: Calendar.current.startOfDay(for: Date()).addingTimeInterval(TimeInterval(p.startMinute * 60)))
            let hour = comps.hour ?? 0
            let minute = comps.minute ?? 0
            self._startTime = State(initialValue: Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!)
            self._duration = State(initialValue: p.durationMinutes)
        } else {
            self._startTime = State(initialValue: Calendar.current.startOfDay(for: Date()).addingTimeInterval(480 * 60))
            self._duration = State(initialValue: 45)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(periodToEdit == nil ? "New Period" : "Edit Period").font(.headline).padding()
                Spacer()
                Button {
                    if let period = periodToEdit {
                        // update existing
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
                        period.startMinute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
                        period.durationMinutes = duration
                    } else {
                        // create new
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
                        let startMinute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
                        let newPeriod = PeriodModel(
                            index: periods.count,
                            startMinute: startMinute,
                            durationMinutes: duration)
                        modelContext.insert(newPeriod)
                    }
                    do {
                        try modelContext.save()
                    } catch {
                        print("❌ Failed saving period: \(error)")
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
                Section(header: Text("time")) {
                    DatePicker(
                        "Start Time",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                Divider()
                Section(header: Text("Duration")) {
                    Picker("", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { value in
                            Text("\(value) min")
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 0.5))
            )
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding()
            Spacer()
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

// PeriodDetailView removed

#Preview {
    EditTimetableView()
}
