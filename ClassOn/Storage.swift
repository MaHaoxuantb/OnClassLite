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
    var number: Int = 0 //Use counter to assign a number to order it
    var day: SevenDay
    var isCommonDay: Bool //If it's commonDay, should follow the timetable
    @Relationship(deleteRule: .cascade)
        var commonClasses = [CommonClass]()
    
    init(id: UUID = UUID(), number: Int = 0, day: SevenDay, isCommonDay: Bool, commonClasses: [CommonClass] = []) {
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
    var time: Int
    var descriptions: String?
    var details: String?
    var parentDay: CommonDaysModel?
    
    init(id: UUID = UUID(), name: String, isCommonClass: Bool, time: Int, description: String? = nil, details: String?, parentDay: CommonDaysModel? = nil) {
        self.id = id
        self.name = name
        self.isCommonClass = isCommonClass
        self.time = time
        self.descriptions = description
        self.details = details
        self.parentDay = parentDay
    }
}

//MARK: -Other Categories
@Model
final class CategoriesModel {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    var descriptions: String?
    var details: String?
    var colorHex: String
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
    }
    @Relationship(deleteRule: .cascade)
        var events = [Event]()
    
    init(id: UUID = UUID(), name: String, description: String? = nil, details: String?, color: Color = .accentColor, events: [Event] = []) {
        self.id = id
        self.name = name
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
    
    var date: Date
    var isAllDay: Bool = false
    var StartTime: Int
    var EndTime: Int?
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
    
    var parentCategory: CategoriesModel?
    @Relationship(deleteRule: .cascade)
        var alarms: [EventAlarms]? = []
    
    init(id: UUID = UUID(), name: String, date: Date, StartTime: Int, needLoop: Bool, description: String? = nil, details: String?, color: Color = .accentColor, parentCategory: CategoriesModel? = nil, alarms: [EventAlarms]? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.StartTime = StartTime
        self.needLoop = needLoop
        self.descriptions = description
        self.details = details
        self.colorHex = color.toHex()
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
