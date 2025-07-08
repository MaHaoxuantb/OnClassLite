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

@Model
final class CommonDays {
    var day: SevenDay
    
    init(day: SevenDay) {
        self.day = day
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
    
    init(name: String, time: Int, description: String? = nil, details: [String: String]?) {
        self.name = name
        self.time = time
        self.descriptions = descriptions
        self.details = details
    }
}

//MARK: -Other Catagories
@Model
final class OtherCatagories {
    var name: String
    
    init(name: String, date: Date, time: Int) {
        self.name = name
    }
}

@Model
final class Events {
    var name: String
    var date: Date
    var time: Int
    
    init(name: String, date: Date, time: Int) {
        self.name = name
        self.date = date
        self.time = time
    }
}
