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
final class CommonDays {
    var day: SevenDay
    var commonClasses: [CommonClass] = []
    
    init(day: SevenDay, commonClasses: [CommonClass] = []) {
        self.day = day
        self.commonClasses = commonClasses
    }
}

extension CommonDays {
    /// Returns one instance per day of the week
    static var allDefaults: [CommonDays] {
        SevenDay.allCases.map { CommonDays(day: $0) }
    }
}

@Model
final class CommonClass {
    var name: String
    var time: Int
    var descriptions: String?
    var details: [String: String]?
    var parentDay: CommonDays?
    
    init(name: String, time: Int, description: String? = nil, details: [String: String]?, parentDay: CommonDays? = nil) {
        self.name = name
        self.time = time
        self.descriptions = description
        self.details = details
        self.parentDay = parentDay
    }
}

//MARK: -Other Catagories
@Model
final class OtherCatagories {
    var name: String
    @Relationship(deleteRule: .cascade) var events: [Event] = []
    
    init(name: String, events: [Event] = []) {
        self.name = name
        self.events = events
    }
}

@Model
final class Event {
    var name: String
    var date: Date
    var time: Int
    var parentCatagory: OtherCatagories?
    
    init(name: String, date: Date, time: Int, parentCatagory: OtherCatagories? = nil) {
        self.name = name
        self.date = date
        self.time = time
        self.parentCatagory = parentCatagory
    }
}
