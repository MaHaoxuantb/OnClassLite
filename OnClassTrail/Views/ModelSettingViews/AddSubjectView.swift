//
//  AddSubjectView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData
import CoreImage.CIFilterBuiltins
import AVFoundation
import OSLog

private let shareLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OnClassLite", category: "Share")

// MARK: - QR Image Wrapper
struct QRImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

private extension ModelContext {
    /// Returns an existing `Teacher` matching *name* or `nil` when none exists.
    func fetchTeacher(named name: String) -> Teacher? {
        let descriptor = FetchDescriptor<Teacher>(predicate: #Predicate { $0.name == name })
        return (try? fetch(descriptor))?.first
    }
}

// MARK: - Sharing Payload
/// Lightweight, shareable representation of a `SubjectModel`
struct SharedSubject: Codable {
    let name: String
    let teachers: [String]
    let colorHex: String
}

private extension SubjectModel {
    /// Convert a subject into its shareable payload.
    var sharedPayload: SharedSubject {
        SharedSubject(
            name: name,
            teachers: teachersForSubject?.map { $0.name } ?? [],
            colorHex: colorHex
        )
    }
}

/// Simple QR‑code generator.
private func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let filter  = CIFilter.qrCodeGenerator()
    filter.setValue(Data(string.utf8), forKey: "inputMessage")

    guard let outputImage = filter.outputImage?
            .transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
          let cgImg = context.createCGImage(outputImage, from: outputImage.extent)
    else { return nil }

    return UIImage(cgImage: cgImg)
}

// MARK: - Custom AVFoundation QR Scanner
struct AVQRScannerView: UIViewControllerRepresentable {
    var onFound: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let session = AVCaptureSession()

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            return vc
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = vc.view.layer.bounds
        vc.view.layer.addSublayer(preview)

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var onFound: (String) -> Void
        init(onFound: @escaping (String) -> Void) { self.onFound = onFound }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection)
        {
            guard
                let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                obj.type == .qr,
                let code = obj.stringValue
            else { return }
            output.setMetadataObjectsDelegate(nil, queue: nil)
            onFound(code)
        }
    }
}

//MARK: -EditSubjectListView
struct EditSubjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SubjectModel.orderId) private var subjects: [SubjectModel]
    @State private var editingSubject: SubjectModel?
    @State private var showScanner   = false
    @State private var qrPayload: QRImageWrapper?

    var body: some View {
        List {
            ForEach(subjects) { subject in
                Button {
                    editingSubject = subject
                } label: {
                    HStack {
                        Circle().fill(subject.color).frame(width: 10, height: 10)
                        Text(subject.name).font(.headline)
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        // Generate single-item QR payload
                        let payload = subject.sharedPayload
                        if let data = try? JSONEncoder().encode([payload]),
                           let json = String(data: data, encoding: .utf8),
                           let img = generateQRCode(from: json) {
                            qrPayload = QRImageWrapper(image: img)
                        }
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
            .onDelete(perform: deleteSubjects)
            .onMove(perform: moveSubjects)
        }
        .navigationTitle(Text("Subjects"))
        .toolbar {
            ToolbarItem {
                Menu {
                    // Manually adding
                    Button {
                        editingSubject = SubjectModel(
                            name: "",
                            teachersForSubject: [],
                            color: .accentColor
                        )
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Image(systemName: "plus")
                        Text("Add Subject")
                    }

                    // Scan incoming QR code
                    Button {
                        showScanner = true
                        HapticsManager.shared.playHapticFeedback()
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan To Add")
                    }

                    // Share current subjects list as QR code
                    Button {
                        shareAllSubjects()
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
        .sheet(item: $editingSubject) { subject in
            SubjectFormView(subject: subject, isPresented: $editingSubject)
        }
        // QR‑code scanner sheet
        .sheet(isPresented: $showScanner) {
            AVQRScannerView { code in
                handleScanned(code: code)
                showScanner = false
            }
        }
        // QR-code display sheet (item-driven)
        .sheet(item: $qrPayload) { payload in
            VStack {
                Image(uiImage: payload.image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding()
                Text("Scan this on another device to import subjects.")
                    .padding()
            }
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
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
    // MARK: - Sharing & Receiving helpers
    private func shareAllSubjects() {
        let payloads = subjects.map { $0.sharedPayload }
        guard let data = try? JSONEncoder().encode(payloads),
              let json = String(data: data, encoding: .utf8),
              let img  = generateQRCode(from: json)
        else { return }
        // Wrap and present via item sheet
        qrPayload = QRImageWrapper(image: img)
    }

    private func handleScanned(code: String) {
        guard let data = code.data(using: .utf8) else {
            shareLogger.warning("Invalid QR code string – UTF‑8 conversion failed")
            return
        }

        // Decode the JSON payload (either an array or a single item)
        let payloads: [SharedSubject]
        do {
            if let many = try? JSONDecoder().decode([SharedSubject].self, from: data) {
                payloads = many
            } else {
                payloads = [try JSONDecoder().decode(SharedSubject.self, from: data)]
            }
        } catch {
            shareLogger.error("QR decode failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        // Determine where to continue `orderId`
        let startIndex = (subjects.compactMap(\.orderId).max() ?? -1) + 1

        // Cache already‑existing teachers to honour the `.unique` constraint
        let existingTeachers = (try? modelContext.fetch(FetchDescriptor<Teacher>())) ?? []
        var teacherCache = Dictionary(uniqueKeysWithValues:
            existingTeachers.map { ($0.name.lowercased(), $0) })

        DispatchQueue.main.async {
            var runningIndex = startIndex

            for subject in payloads {
                // Resolve teacher entities, re‑using instances when possible
                let teachers = subject.teachers.map { tName -> Teacher in
                    let key = tName.lowercased()
                    if let cached = teacherCache[key] { return cached }
                    let newT = Teacher(name: tName)
                    modelContext.insert(newT)
                    teacherCache[key] = newT
                    return newT
                }

                let newSubject = SubjectModel(
                    orderId: runningIndex,
                    name: subject.name,
                    teachersForSubject: teachers,
                    color: Color(hex: subject.colorHex)
                )
                runningIndex += 1
                modelContext.insert(newSubject)
            }

            do {
                try modelContext.save()
            } catch {
                shareLogger.error("Saving scanned subjects failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}


// MARK: - SubjectFormView (Add & Edit)
struct SubjectFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var subject: SubjectModel?
    @State private var name: String
    @State private var teachersText: String
    @State private var color: Color
    @State private var periods: [PeriodModel]

    init(subject: SubjectModel? = nil, isPresented: Binding<SubjectModel?>) {
        self._subject = isPresented
        if let sub = subject {
            _name = State(initialValue: sub.name)
            _teachersText = State(initialValue: sub.teachersForSubject?.map(\.name).joined(separator: ", ") ?? "")
            _color = State(initialValue: sub.color)
            // Always initialize periods to default periods
            _periods = State(initialValue: PeriodModel.defaultPeriods())
        } else {
            _name = State(initialValue: "")
            _teachersText = State(initialValue: "")
            _color = State(initialValue: .accentColor)
            _periods = State(initialValue: PeriodModel.defaultPeriods())
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    TextField("Teachers (comma separated)", text: $teachersText)
                    ColorPicker("Color", selection: $color)
                }
                Section(header: Text("Periods")) {
                    ForEach(periods, id: \.id) { period in
                        HStack {
                            Text("Period \(period.index + 1)")
                            Spacer()
                            Text("\(period.startMinute/60):\(String(format: "%02d", period.startMinute%60))")
                        }
                    }
                }
            }
            .navigationTitle(subject == nil ? "New Subject" : "Edit Subject")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveSubject()
                        subject = nil
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { subject = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }

    private func saveSubject() {
        // Build Teacher entities
        let teacherNames = teachersText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let teacherEntities: [Teacher] = teacherNames.map { tName in
            if let existing = modelContext.fetchTeacher(named: tName) { return existing }
            let newT = Teacher(name: tName)
            modelContext.insert(newT)
            return newT
        }
        let sub = subject ?? SubjectModel(name: name, teachersForSubject: teacherEntities, color: color)
        sub.name = name
        sub.teachersForSubject = teacherEntities
        sub.color = color
        // Do not persist periods here
        if subject == nil {
            modelContext.insert(sub)
        }
        try? modelContext.save()
    }
}
