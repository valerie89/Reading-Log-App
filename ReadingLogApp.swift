//
//  ReadingLogApp.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct ReadingLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var session = SessionManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Book.self, ReadingSession.self, Goal.self, Board.self])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
        .modelContainer(sharedModelContainer)
    }
}
