//
//  LoginView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import SwiftUI

struct LoginView: View {
    let onLoginSuccess: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Log In")
                .font(.system(size: 28, weight: .semibold, design: .serif))

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding(14)
                .background(.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            SecureField("Password", text: $password)
                .padding(14)
                .background(.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                onLoginSuccess() 
            } label: {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.black.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(22)
        .navigationBarTitleDisplayMode(.inline)
    }
}
