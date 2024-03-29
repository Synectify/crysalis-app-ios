//
//  VIew+.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 02.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func ignoresKeyboard() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea(.keyboard)
        } else {
            self
        }
    }
}

extension View {
	func toAnyView() -> AnyView {
		AnyView(self)
	}
}
