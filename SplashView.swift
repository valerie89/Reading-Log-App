//
//  SplashView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color("BrandGreen")
                .ignoresSafeArea()

            Text("Grove")
                .font(.system(size: 56, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    SplashView()
}
