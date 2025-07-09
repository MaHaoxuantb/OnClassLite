//
//  Item.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import Foundation
import SwiftData
import SwiftUI //This is for storing colors

//MARK: -Common days & Classes
enum SevenDay: String, CaseIterable, Codable {
    case Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
}

// this main model always exist, and could not be deleted.
@Model
final class CommonDaysModel {
    @Attribute(.unique)
        var id: UUID = UUID()
    var number: Int //Use counter to assign a number to order it, started at 0 for Monday
    var day: SevenDay
    var isCommonDay: Bool //If it's commonDay, should follow the timetable
    @Relationship(deleteRule: .cascade)
        var commonClasses = [CommonClass]()
    
    init(id: UUID = UUID(), number: Int, day: SevenDay, isCommonDay: Bool, commonClasses: [CommonClass] = []) {
        self.id = id
        self.number = number
        self.day = day
        self.isCommonDay = isCommonDay
        self.commonClasses = commonClasses
    }
}

//MARK: Classes
@Model
final class CommonClass {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    
    var isCommonClass: Bool
    var startMinute: Int
    /// Duration of the period in minutes.
    var durationMinutes: Int
    var descriptions: String?
    var details: String?
    
    var colorHex: String
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
    }
    
    var parentDay: CommonDaysModel?
    
    init(
        id: UUID = UUID(),
        name: String,
        isCommonClass: Bool,
        startMinute: Int,
        durationMinutes: Int,
        description: String? = nil,
        details: String? = nil,
        color: Color = .accentColor,
        parentDay: CommonDaysModel? = nil
    ) {
        self.id = id
        self.name = name
        self.isCommonClass = isCommonClass
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
        self.descriptions = description
        self.details = details
        self.colorHex = color.toHex()
        self.parentDay = parentDay
    }
}

// MARK: - SchoolSchedule
struct SchoolSchedule {
    /// Default period start times in minutes since midnight.
    static let periodStartMinutes: [Int] = [
        480,  // 8:00 AM
        530,  // 8:50 AM
        585,  // 9:45 AM
        640,  // 10:40 AM
        690,  // 11:30 AM
        735,  // 12:15 PM
        785,  // 1:05 PM
        835,  // 1:55 PM
        890,  // 2:50 PM
        940,  // 3:40 PM
        990   // 4:30 PM
    ]
    /// Default lesson durations in minutes (parallel to `periodStartMinutes`).
    static let periodDurationMinutes: [Int] = [
        45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45
    ]
}


//MARK: -Other Categories
@Model
final class CategoriesModel {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    var sortIndex: Int  // <- This is used for sorting
    var descriptions: String?
    var details: String?
    var colorHex: String
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
    }
    @Relationship(deleteRule: .cascade)
        var events = [Event]()
    
    init(id: UUID = UUID(), name: String, sortIndex: Int, description: String? = nil, details: String?, color: Color = .accentColor, events: [Event] = []) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.descriptions = description
        self.details = details
        self.colorHex = color.toHex()
        self.events = events
    }
}

//MARK: Event
@Model
final class Event {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    
    var date: Date //If full day, store the timeStamp for 00:00
    var isAllDay: Bool = false
    var duration: Int? //min
    var needLoop: Bool
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var descriptions: String?
    var details: String?
    /// Stored as "#RRGGBB"
    var colorHex: String
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
    }
    
    var isReminder: Bool = false
    var reminderFinished: Bool = false
    
    var parentCategory: CategoriesModel?
    @Relationship(deleteRule: .cascade)
        var alarms: [EventAlarms]? = []
    
    init(
        id: UUID = UUID(),
        name: String,
        
        date: Date,
        duration: Int,
        needLoop: Bool,
        
        createAt: Date = Date(),
        updatedAt: Date = Date(),
        
        description: String? = nil,
        details: String?,
        
        color: Color = .accentColor,
        
        isReminder: Bool,
        reminderFinished: Bool,
        
        parentCategory: CategoriesModel? = nil,
        alarms: [EventAlarms]? = nil
    ) {
        self.id = id
        self.name = name
        
        self.date = date
        self.duration = duration
        self.needLoop = needLoop
        
        self.createdAt = createAt
        self.updatedAt = updatedAt
        
        self.descriptions = description
        self.details = details
        self.colorHex = color.toHex()
        
        self.isReminder = isReminder
        self.reminderFinished = reminderFinished
        
        self.parentCategory = parentCategory
    }
}

//MARK: alarms
@Model
final class EventAlarms {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    var date: Date
    var time: Int
    var parentEvent: Event?
    
    init(id: UUID = UUID(), name: String, date: Date, time: Int, parentEvent: Event? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.time = time
    }
}


// MARK: - CommonClass Default Classes Extension
extension CommonClass {
    static func defaultClasses(for parentDay: CommonDaysModel?) -> [CommonClass] {
        zip(SchoolSchedule.periodStartMinutes, SchoolSchedule.periodDurationMinutes)
            .enumerated()
            .map { index, pair in
                let (minute, duration) = pair
                return CommonClass(
                    name: "Period \(index + 1)",
                    isCommonClass: true,
                    startMinute: minute,
                    durationMinutes: duration,
                    parentDay: parentDay
                )
            }
    }
}
