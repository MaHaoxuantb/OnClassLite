//
//  StorageDebug.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI
import SwiftData

struct StorageDebug: View {
    @Query(sort: \SubjectModel.orderId) private var subjects: [SubjectModel]
    
    var body: some View {
        VStack {
            Button("Subjects") {
                print("Subjects count: \(subjects.count)")
                for subject in subjects {
                    print("Subject: \(subject.name), id: \(subject.id)")
                }
            }
        }
        .navigationTitle(Text("Storage Debug"))
    }
}

#Preview {
    StorageDebug()
        .modelContainer(for: SubjectModel.self)
}
