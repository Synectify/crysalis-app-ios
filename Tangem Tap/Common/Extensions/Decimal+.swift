//
//  Decimal_.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 02.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension Decimal {
    func currencyFormatted(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.roundingMode = .down 
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self) \(code)"
    }
}
