//
//  BookStatus.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/11/26.
//
import Foundation

enum BookStatus: String, Codable, CaseIterable {
    case reading
    case wishlist
    case finished
    case dnf

    var displayName: String {
        switch self {
        case .reading: return "Currently Reading"
        case .wishlist: return "Wishlist"
        case .finished: return "Finished"
        case .dnf: return "Didn't Finish"
        }
    }
}
extension Book {
    var status: BookStatus {
        get { BookStatus(rawValue: statusRaw) ?? .reading }
        set { statusRaw = newValue.rawValue }
    }
}

