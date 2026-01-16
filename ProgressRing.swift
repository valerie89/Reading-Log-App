//
//  ProgressRing.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/13/26.
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .foregroundStyle(Color(.systemGray5))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .foregroundStyle(Color("BrandGreen"))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}
