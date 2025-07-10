//
//  CalendarView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        ScrollView {
            Text("This is calendar view.")
                .padding()
            Text("display upcomming events")
                .padding()
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

#Preview {
    CalendarView()
}
