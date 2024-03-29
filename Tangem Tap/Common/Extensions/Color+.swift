//
//  Color+.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 03.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    
    //MARK: Primary
    
    @nonobjc static var tangemTapGreen: Color {
        return Color("tangem_tap_green")
    }
    
    @nonobjc static var tangemTapGreen1: Color {
        return Color("tangem_tap_green1")
    }
    
    @nonobjc static var tangemTapGreen2: Color {
        return Color("tangem_tap_green2")
    }
    
    //MARK: Complimentary
    
    @nonobjc static var tangemTapWarning: Color {
        return Color("tangem_tap_warning")
    }
    
    @nonobjc static var tangemTapBlue: Color {
        return Color("tangem_tap_blue")
    }
    
    @nonobjc static var tangemTapBlue1: Color {
        return Color("tangem_tap_blue1")
    }
    
    @nonobjc static var tangemTapBlue2: Color {
        return Color("tangem_tap_blue2")
    }
    
    @nonobjc static var tangemTapBlue3: Color {
        return Color("tangem_tap_blue3")
    }
    
    @nonobjc static var tangemTapCritical: Color {
        return Color(.tangemTapCritical)
    }
    
    //MARK: Gray Dark
    
    @nonobjc static var tangemTapGrayDark: Color {
        return Color("tangem_tap_gray_dark")
    }
    
    @nonobjc static var tangemTapGrayDark2: Color {
        return Color("tangem_tap_gray_dark2")
    }
    
    @nonobjc static var tangemTapGrayDark3: Color {
        return Color("tangem_tap_gray_dark3")
    }
    
    @nonobjc static var tangemTapGrayDark4: Color {
        return Color("tangem_tap_gray_dark4")
    }
    
    @nonobjc static var tangemTapGrayDark5: Color {
        return Color("tangem_tap_gray_dark5")
    }
    
    @nonobjc static var tangemTapGrayDark6: Color {
        return Color("tangem_tap_gray_dark6")
    }
    
    //MARK: Gray Light
    
    @nonobjc static var tangemTapGrayLight4: Color {
        return Color("tangem_tap_gray_light4")
    }
    
    @nonobjc static var tangemTapGrayLight5: Color {
        return Color("tangem_tap_gray_light5")
    }
    
    @nonobjc static var tangemTapGrayLight6: Color {
        return Color("tangem_tap_gray_light6")
    }
    
    //MARK: Background
    
    @nonobjc static var tangemTapBgGray: Color {
		return Color(.tangemTapBgGray)
    }
	
	@nonobjc static var tangemTapBgGray2: Color {
		return Color(.tangemTapBgGray2)
	}
    
    @nonobjc static var tangemTapBg: Color {
        return Color("tangem_tap_bg")
    }
    
    //MARK: Tints
    
    @nonobjc static var tangemTapBlueLight: Color {
        return Color("tangem_tap_blue_light")
    }
	
	@nonobjc static var tangemTapBlueLight2: Color {
		return Color("tangem_tap_blue_light2")
	}
}

extension UIColor {
    //MARK: Background
    @nonobjc static var tangemTapBgGray: UIColor {
        return UIColor(named: "tangem_tap_bg_gray")!
    }
	
	@nonobjc static var tangemTapBgGray2: UIColor {
		return UIColor(named: "tangem_tap_bg_gray2")!
	}
    
    @nonobjc static var tangemTapGrayDark4: UIColor {
        return UIColor(named: "tangem_tap_gray_dark4")!
       }
    
    @nonobjc static var tangemTapGrayDark6: UIColor {
        return UIColor(named: "tangem_tap_gray_dark6")!
       }
    
    @nonobjc static var tangemTapBlue: UIColor {
        return UIColor(named: "tangem_tap_blue")!
    }
    
    @nonobjc static var tangemTapGrayDark: UIColor {
        return UIColor(named: "tangem_tap_gray_dark")!
    }
    
    @nonobjc static var tangemTapCritical: UIColor {
        UIColor(named: "tangem_tap_critical")!
    }
}


extension Color {
    public init?(hex: String) {
        let r, g, b, a: Double
        
        let hexColor = hex.stripHexPrefix().remove("#")
        if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xff000000) >> 24) / 255
                g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                a = Double(hexNumber & 0x000000ff) / 255
                
                self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                return
            }
        }
        
        return nil
    }
}
