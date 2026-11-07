//
//  ContentView.swift
//  BarHopping
//
//  Created by 蔡承曄 on 2026/11/7.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    TabLandingView(tab: tab)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
