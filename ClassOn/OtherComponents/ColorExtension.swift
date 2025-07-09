//
//  ColorExtension.swift
//  ClassOn
//
//  Created by Thomas B on 7/9/25.
//

// This file is used as an extension to store colors in SwiftData
import SwiftUI
import UIKit

struct ColorCodable: Codable, Hashable {
    var color: Color

    init(_ color: Color) {
        self.color = color
    }

    enum CodingKeys: String, CodingKey {
        case hex
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hex = String(format: "#%02lX%02lX%02lX", Int(red * 255), Int(green * 255), Int(blue * 255))
        try container.encode(hex, forKey: .hex)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hex = try container.decode(String.self, forKey: .hex)
        self.color = Color(hex: hex)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        _ = scanner.scanString("#") // skip #
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
    
    /// Convert this Color to its "#RRGGBB" hex string
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
