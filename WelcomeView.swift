//
//  WelcomeView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct WelcomeView: View {
    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandGreen")
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer()

                    // Centered title + subtitle
                    VStack(spacing: 14) {
                        Text("Grove")
                            .font(.system(size: 44, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)

                        Text("A calm place to track your reading.")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer()

                    // Buttons at bottom
                    VStack(spacing: 12) {

                        Button(action: signInWithGoogle) {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)

                        // Email login
                        NavigationLink {
                            LoginView(onLoginSuccess: onLoginSuccess)
                        } label: {
                            Text("Log in with email")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white.opacity(0.18))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)

                        // Signup
                        NavigationLink {
                            SignupView(onSignupSuccess: onLoginSuccess)
                        } label: {
                            Text("Sign up")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white.opacity(0.10))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 4)
                }
                .padding(22)
            }
        }
    }

    private func signInWithGoogle() {
        print("✅ GOOGLE BUTTON TAPPED")

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ Missing clientID. GoogleService-Info.plist not found in target or Firebase not configured.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get top view controller to present Google Sign-In screen
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("❌ No root view controller found")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                print("❌ Google Sign-In error:", error)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("❌ Missing ID token from Google user")
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    print("❌ Firebase Auth error:", error)
                } else {
                    print("✅ Signed in with Google")
                    onLoginSuccess()
                }
            }
        }
    }
}

