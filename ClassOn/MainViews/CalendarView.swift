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
struct CalendarView: View {
    // All days kept in SwiftData.
    @Query(sort: \CommonDaysModel.number) private var allDays: [CommonDaysModel]

    // Compute the next set of classes (today → six days ahead).
    private var upcomingClasses: [CommonClass] {
        let cal         = Calendar.current
        let nowMinutes  = cal.component(.hour,   from: .now) * 60 +
                          cal.component(.minute, from: .now)

        let todayIndex  = cal.weekdayIndexToday        // 0 = Mon … 6 = Sun
        var result: [CommonClass] = []

        for offset in 0..<7 {                          // look up to one week ahead
            let idx   = (todayIndex + offset) % 7
            guard let day = allDays.first(where: { $0.number == idx && $0.isCommonDay })
            else { continue }

            // -- Filter out past classes on the current day – keep everything for later days.
            let filtered = day.commonClasses.filter { cls in
                offset == 0 ? cls.startMinute >= nowMinutes : true
            }

            result.append(contentsOf: filtered)
        }

        // Sort first by weekday, then by startMinute.
        return result.sorted {
            let d1 = $0.parentDay?.number ?? 0
            let d2 = $1.parentDay?.number ?? 0
            return d1 == d2 ? $0.startMinute < $1.startMinute : d1 < d2
        }
    }

    var body: some View {
        NavigationStack {
            if upcomingClasses.isEmpty {
                ContentUnavailableView("No upcoming classes 🎉",
                                       systemImage: "checkmark.seal")
            } else {
                List {
                    ForEach(upcomingClasses, id: \.id) { cls in
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
                .listStyle(.plain)
                .navigationTitle("Upcoming Classes")
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
    CalendarView()
        .modelContainer(
            for: [CommonDaysModel.self,
                  CategoriesModel.self,
                  CommonClass.self,
                  SubjectModel.self,
                  PeriodModel.self],
        )
}
