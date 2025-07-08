//
//  Item.swift
//  ClassOn
//
//  Created by Thomas B on 7/8/25.
//

import Foundation
import SwiftData

//MARK: -Common days
enum SevenDay: String, CaseIterable, Codable {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
}

// this main model always exist, and could not be deleted.
@Model
final class CommonDaysModel {
    @Attribute(.unique) var id: UUID = UUID()
    var day: SevenDay
    @Relationship(deleteRule: .cascade) var commonClasses = [CommonClass]()
    
    init(id: UUID = UUID(), day: SevenDay, commonClasses: [CommonClass] = []) {
        self.id = UUID()
        self.day = day
        self.commonClasses = commonClasses
    }
}

@Model
final class CommonClass {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var time: Int
    var descriptions: String?
    var details: String?
    var parentDay: CommonDaysModel?
    
    init(id: UUID = UUID(), name: String, time: Int, description: String? = nil, details: String?, parentDay: CommonDaysModel? = nil) {
        self.id = UUID()
        self.name = name
        self.time = time
        self.descriptions = description
        self.details = details
        self.parentDay = parentDay
    }
}

//MARK: -Other Categories
@Model
final class CategoriesModel {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    @Relationship(deleteRule: .cascade) var events = [Event]()
    
    init(id: UUID = UUID(), name: String, events: [Event] = []) {
        self.id = id
        self.name = name
        self.events = events
    }
}

@Model
final class Event {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var date: Date
    var time: Int
    var descriptions: String?
    var details: String?
    var parentCategory: CategoriesModel?
    
    init(id: UUID = UUID(), name: String, date: Date, time: Int, description: String? = nil, details: String?, parentCategory: CategoriesModel? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.time = time
        self.descriptions = description
        self.details = details
        self.parentCategory = parentCategory
    }
}
