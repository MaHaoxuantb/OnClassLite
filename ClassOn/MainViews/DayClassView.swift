//
//  CalendarView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//
//  This View has help by ChatGPT
//

import SwiftUI
import SwiftData

// MARK: - Helpers
private extension Int {
    /// Converts minutes-since-midnight to a localised “h:mm a” string.
    var clockString: String {
        let hours   = self / 60
        let minutes = self % 60
        var comps   = DateComponents()
        comps.hour  = hours
        comps.minute = minutes
        let date = Calendar.current.date(from: comps) ?? .now
        return date.formatted(.dateTime.hour().minute())
    }
}

private extension Calendar {
    /// Monday-based weekday index (Mon = 0 … Sun = 6).
    var weekdayIndexToday: Int {
        // In the Gregorian calendar Sunday = 1 … Saturday = 7.
        // Shift so that Monday is 0.
        let today = component(.weekday, from: .now)   // 1 … 7
        return (today + 5) % 7                        // 0 … 6
    }
}

// MARK: - View
struct DayClassView: View {
    // All days kept in SwiftData.
    @Query(sort: \CommonDaysModel.number) private var allDays: [CommonDaysModel]
    
    /// Current weekday index (Mon = 0 … Sun = 6)
    private var dayIndex: Int {
        Calendar.current.weekdayIndexToday
    }
    
    // MARK: - Classes for the selected day
    private var classesForDay: [CommonClass] {
        guard let day = allDays.first(where: { $0.number == dayIndex })
        else { return [] }
        return day.commonClasses.sorted { $0.startMinute < $1.startMinute }
    }
    
    var body: some View {
        NavigationStack {
            if classesForDay.isEmpty {
                ContentUnavailableView("No upcoming classes 🎉",
                                       systemImage: "checkmark.seal")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(classesForDay, id: \.id) { cls in
                        ClassCardView(cls: cls)
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.regularMaterial)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 2)
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listStyle(.plain)
                .navigationTitle("\(SevenDay.allCases[dayIndex].rawValue) Classes")
            }
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

// MARK: - Card
private struct ClassCardView: View {
    let cls: CommonClass

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // coloured bar
            RoundedRectangle(cornerRadius: 4)
                .fill(cls.color)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 4) {
                // title
                Text(cls.name)
                    .font(.headline)

                // timing
                Text("\(cls.startMinute.clockString) – \((cls.startMinute + cls.durationMinutes).clockString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // teacher
                if let teacher = cls.teacherForClass?.name {
                    Text(teacher)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // description (if any)
                if let desc = cls.descriptions, !desc.isEmpty {
                    Text(desc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Preview
#Preview {
    DayClassView()
        .modelContainer(
            for: [CommonDaysModel.self,
                  CategoriesModel.self,
                  CommonClass.self,
                  SubjectModel.self,
                  PeriodModel.self],
        )
}
