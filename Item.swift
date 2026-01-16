//
//  Item.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
