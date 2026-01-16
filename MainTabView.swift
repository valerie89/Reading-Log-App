//
//  MainTabView.swift
//  ReadingLog
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }

            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: "books.vertical") }

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(.white)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color("BrandGreen"), for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
