//
//  ContentView.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 30.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import SwiftUI

struct ContentView<Content: View>: View {
    let content: () -> Content
    init (@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        NavigationView {
            content()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView() {
            Text("Hello")
        }
        .previewGroup(devices: [.iPhone12Pro])
    }
}
