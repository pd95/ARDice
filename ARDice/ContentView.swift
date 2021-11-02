//
//  ContentView.swift
//  ARDice
//
//  Created by Philipp on 02.11.21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ARContainerView()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
