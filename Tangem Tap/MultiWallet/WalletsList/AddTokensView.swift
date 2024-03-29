//
//  AddTokensView.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 20.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AddTokensView: View {
    var action: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            Button(action: {
                action()
            }, label: {
                Text("+ \("wallet_add_tokens".localized)")
                    .frame(width: geo.size.width, height: 56)
            })
            .foregroundColor(.black)
            .frame(width: geo.size.width, height: 56)
        }
        .frame(height: 56)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .tangemTapGrayLight5, radius: 2, x: 0, y: 1)
    }
}

struct AddTokensView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.tangemTapGrayLight5
            AddTokensView(action: {})
                .padding()
        }
    }
}
