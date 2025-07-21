//
//  CalendarView.swift
//  OnClassLite
//
//  Created by Thomas B on 7/10/25.
//
//  This View has helped by ChatGPT
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

/// Short “Jul 21”‑style date used in the navigation title.
private extension Date {
    var shortDateString: String {
        formatted(.dateTime.month(.abbreviated).day())
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
struct HomeView: View {
    // All days kept in SwiftData.
    @Query(sort: \CommonDaysModel.number) private var allDays: [CommonDaysModel]
    
    // All events kept in SwiftData.
    @Query(sort: \Event.date) private var allEvents: [Event]
    
    /// Minutes‑since‑midnight for the current moment.
    private var nowMinute: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: .now)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    // MARK: – Events for today
    private var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }
    private var endOfToday: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
    }
    private var eventsForDay: [Event] {
        allEvents.filter { $0.date >= startOfToday && $0.date < endOfToday }
    }

    // MARK: – Combined schedule items (classes + events)
    private struct ScheduleItem: Identifiable {
        let id: UUID
        let startMinute: Int
        let isClass: Bool
        let cls: CommonClass?
        let event: Event?
    }
    private var scheduleItems: [ScheduleItem] {
        var items: [ScheduleItem] = []

        // classes
        for cls in classesForDay {
            items.append(
                ScheduleItem(id: cls.id,
                             startMinute: cls.startMinute,
                             isClass: true,
                             cls: cls,
                             event: nil)
            )
        }

        // events
        for ev in eventsForDay {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: ev.date)
            let minute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            items.append(
                ScheduleItem(id: ev.id,
                             startMinute: minute,
                             isClass: false,
                             cls: nil,
                             event: ev)
            )
        }

        // sort by time; if times tie, classes come first
        return items.sorted {
            if $0.startMinute == $1.startMinute {
                return $0.isClass && !$1.isClass
            }
            return $0.startMinute < $1.startMinute
        }
    }

    /// The `id` of the next (or current) schedule item for today, if there is one.
    private var nextItemId: UUID? {
        scheduleItems.first(where: { $0.startMinute >= nowMinute })?.id
    }
    
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
                    ForEach(scheduleItems) { item in
                        if item.isClass, let cls = item.cls {
                            ClassCardView(cls: cls, isUpcoming: item.id == nextItemId)
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.thickMaterial)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 2)
                                )
                        } else if let ev = item.event {
                            EventCardView(event: ev, isUpcoming: item.id == nextItemId)
                                .listRowSeparator(.hidden)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.thinMaterial)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 2)
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)   // hide default list background
                .navigationTitle("\(SevenDay.allCases[dayIndex].rawValue) · \(Date().shortDateString)")
            }
        }
        .background {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onAppear {
            HapticsManager.shared.playHapticFeedback()
        }
    }
}

// MARK: - Card
private struct ClassCardView: View {
    let cls: CommonClass
    let isUpcoming: Bool

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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: isUpcoming ? 3 : 0)
        )
    }
}

// MARK: – Event Card
private struct EventCardView: View {
    let event: Event
    let isUpcoming: Bool

    private var startMinute: Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: event.date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // coloured bar
            RoundedRectangle(cornerRadius: 4)
                .fill(event.color)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 4) {
                // title
                Text(event.name)
                    .font(.headline)

                // timing
                if event.isAllDay {
                    Text("All‑day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let endMinute = startMinute + (event.duration ?? 0)
                    Text("\(startMinute.clockString) – \(endMinute.clockString)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // description (if any)
                if let desc = event.descriptions, !desc.isEmpty {
                    Text(desc)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: isUpcoming ? 3 : 0)
        )
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .modelContainer(
            for: [CommonDaysModel.self,
                  CategoriesModel.self,
                  CommonClass.self,
                  SubjectModel.self,
                  PeriodModel.self,
                  Event.self],
        )
}
