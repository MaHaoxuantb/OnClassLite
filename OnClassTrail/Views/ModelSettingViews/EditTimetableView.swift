//
//  EditTimetableView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import AVFoundation

/// Shareable representation of a PeriodModel for QR transfer
struct SharedPeriod: Codable {
    let index: Int
    let startMinute: Int
    let durationMinutes: Int
}

private extension PeriodModel {
    /// Convert a period into its shareable payload.
    var sharedPayload: SharedPeriod {
        SharedPeriod(index: index,
                     startMinute: startMinute,
                     durationMinutes: durationMinutes)
    }
}

/// Simple QR‑code generator.
private func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let filter  = CIFilter.qrCodeGenerator()
    filter.setValue(Data(string.utf8), forKey: "inputMessage")

    guard let outputImage = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
          let cgImg = context.createCGImage(outputImage, from: outputImage.extent)
    else { return nil }

    return UIImage(cgImage: cgImg)
}

//MARK: -EditTimetableView
struct EditTimetableView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeriodModel.index) private var periods: [PeriodModel]
    @State private var showExpandedTools: Bool = false
    @State private var selectedPeriod: PeriodModel?
    // QR‑sharing state
    @State private var showScanner = false
    @State private var qrPayload: QRImageWrapper?
    @State private var incomingPayloads: [SharedPeriod] = []
    @State private var showOverwriteAlert = false
    
    var body: some View {
        List {
            ForEach(periods) { period in
                Button {
                    selectedPeriod = period
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
                        // Prepare a new period for creation
                        let newIndex = periods.count
                        let defaultStartMinute = 480 // 8:00 AM
                        selectedPeriod = PeriodModel(index: newIndex, startMinute: defaultStartMinute, durationMinutes: 45)
                    } label: {
                        Image(systemName: "plus")
                        Text("Add Period")
                    }
                    
                    Button {
                        showScanner = true
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan To Import")
                    }
                    Button {
                        shareAllPeriods()
                        HapticsManager.shared.playHapticFeedback()
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
        .sheet(item: $selectedPeriod) { period in
            AddPeriodView(
                isPresented: Binding(
                    get: { selectedPeriod != nil },
                    set: { newValue in if !newValue { selectedPeriod = nil } }
                ),
                periodToEdit: period
            )
        }
        // QR‑code scanner sheet
        .sheet(isPresented: $showScanner) {
            AVQRScannerView { code in
                handleScanned(code: code)
                showScanner = false
            }
        }
        // QR‑code display sheet
        .sheet(item: $qrPayload) { payload in
            VStack {
                Image(uiImage: payload.image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding()
                Text("Scan this on another device to import the timetable.")
                    .padding()
            }
        }
        // Overwrite confirmation alert
        .alert("Replace current timetable?", isPresented: $showOverwriteAlert) {
            Button("Cancel", role: .cancel) { incomingPayloads = [] }
            Button("Replace", role: .destructive) {
                importPeriods(incomingPayloads)
                incomingPayloads = []
            }
        } message: {
            Text("Importing via QR code will delete all existing periods and add the ones from the QR code.")
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
    
    // MARK: - QR Sharing & Import
    private func shareAllPeriods() {
        let payloads = periods.map { $0.sharedPayload }
        guard let data = try? JSONEncoder().encode(payloads),
              let json = String(data: data, encoding: .utf8),
              let img  = generateQRCode(from: json) else { return }
        qrPayload = QRImageWrapper(image: img)
    }

    private func handleScanned(code: String) {
        guard let data = code.data(using: .utf8) else { return }
        let decoder = JSONDecoder()
        let payloads: [SharedPeriod]
        if let many = try? decoder.decode([SharedPeriod].self, from: data) {
            payloads = many
        } else if let single = try? decoder.decode(SharedPeriod.self, from: data) {
            payloads = [single]
        } else { return }
        incomingPayloads = payloads
        showOverwriteAlert = true
    }

    private func importPeriods(_ payloads: [SharedPeriod]) {
        // Remove existing periods
        withAnimation { periods.forEach(modelContext.delete) }
        try? modelContext.save()

        // Insert new periods sorted by original index
        for (idx, p) in payloads.sorted(by: { $0.index < $1.index }).enumerated() {
            let newP = PeriodModel(index: idx,
                                   startMinute: p.startMinute,
                                   durationMinutes: p.durationMinutes)
            modelContext.insert(newP)
        }
        try? modelContext.save()
        HapticsManager.shared.playHapticFeedback()
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
