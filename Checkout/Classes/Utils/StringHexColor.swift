//
//  UIColor+Hex.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-07.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//
// Found here: https://gist.github.com/arshad/de147c42d7b3063ef7bc
//

import UIKit

extension String {
    var hexColor: UIColor {
        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return UIColor.clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

//"#f00".hexColor       // r 1.0 g 0.0 b 0.0 a 1.0
//"#be1337".hexColor    // r 0.745 g 0.075 b 0.216 a 1.0
//"#12345678".hexColor  // r 0.204 g 0.337 b 0.471 a 0.071
