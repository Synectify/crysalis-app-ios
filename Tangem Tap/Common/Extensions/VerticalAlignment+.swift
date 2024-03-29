//
//  FirstBaselignAlignment.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 29.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI


extension VerticalAlignment {
    private enum FirstBaselineCustomAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.firstTextBaseline]
        }
    }
    
    static let firstBaselineCustom = VerticalAlignment(FirstBaselineCustomAlignment.self)
}



extension VerticalAlignment {
    private enum TextAndImage: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.bottom]
        }
    }
    
    static let textAndImage = VerticalAlignment(TextAndImage.self)
}
