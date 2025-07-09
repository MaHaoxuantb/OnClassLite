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
    @Relationship(deleteRule: .cascade)
        var commonClasses = [CommonClass]()
    
    init(id: UUID = UUID(), number: Int = 0, day: SevenDay, commonClasses: [CommonClass] = []) {
        self.id = id
        self.number = number
        self.day = day
        self.commonClasses = commonClasses
    }
}

@Model
final class CommonClass {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    var time: Int
    var descriptions: String?
    var details: String?
    var parentDay: CommonDaysModel?
    
    init(id: UUID = UUID(), name: String, time: Int, description: String? = nil, details: String?, parentDay: CommonDaysModel? = nil) {
        self.id = id
        self.name = name
        self.time = time
        self.descriptions = description
        self.details = details
        self.parentDay = parentDay
    }
}

//MARK: -Other Categories & Events
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


@Model
final class Event {
    @Attribute(.unique)
        var id: UUID = UUID()
    var name: String
    var date: Date
    var time: Int
    var needLoop: Bool //If an event is a class, it need to be loop for every 7 days
    var descriptions: String?
    var details: String?
    /// Stored as "#RRGGBB"
    var colorHex: String
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
    }
    var parentCategory: CategoriesModel?
    
    init(id: UUID = UUID(), name: String, date: Date, time: Int, needLoop: Bool, description: String? = nil, details: String?, color: Color = .accentColor, parentCategory: CategoriesModel? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.time = time
        self.needLoop = needLoop
        self.descriptions = description
        self.details = details
        self.colorHex = color.toHex()
        self.parentCategory = parentCategory
    }
}
