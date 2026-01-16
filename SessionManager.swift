//
//  SessionManager.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/6/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class SessionManager: ObservableObject {
    
    var userId: String? { user?.uid }
    @Published var user: User?

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signOut() {
        do { try Auth.auth().signOut() }
        catch { print("Sign out error:", error) }
    }
}
