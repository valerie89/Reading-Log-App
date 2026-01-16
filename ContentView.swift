//
//  ContentView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//
import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @State private var isLoggedIn = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if isLoggedIn {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    WelcomeView(onLoginSuccess: {
                        isLoggedIn = true
                    })
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
