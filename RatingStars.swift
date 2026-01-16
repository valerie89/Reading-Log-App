//
//  RatingStars.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/6/26.
//

import SwiftUI

struct RatingStars: View {
    let rating: Int
    let onSet: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundStyle(i <= rating ? Color.yellow : Color(.systemGray3))
                    .onTapGesture { onSet(i) }
                    .accessibilityLabel("Set rating \(i)")
            }
        }
        .font(.system(size: 14))
    }
}
