//
//  Models.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/6/26.
//
import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var ownerId: String

    // Google Books
    var googleVolumeId: String
    var title: String
    var authors: String
    var coverURL: String?
    
    // Progress + sorting
    var totalPages: Int?
    var lastReadAt: Date?

    // Status
    var statusRaw: String
    var createdAt: Date
    var rating: Int = 0  

    init(ownerId: String,
         googleVolumeId: String,
         title: String,
         authors: String,
         coverURL: String?,
         statusRaw: String = "reading",
         totalPages: Int? = nil) {
        
        self.id = UUID()
        self.ownerId = ownerId
        self.googleVolumeId = googleVolumeId
        self.title = title
        self.authors = authors
        self.coverURL = coverURL
        self.statusRaw = statusRaw
        self.createdAt = Date()
        self.totalPages = totalPages
        self.lastReadAt = nil

    }
}


@Model
final class ReadingSession {
    var id: UUID
    var ownerId: String

    // Relationship
    var book: Book?

    // Stats inputs
    var date: Date
    var minutes: Int
    var pages: Int

    init(ownerId: String, book: Book?, date: Date = Date(), minutes: Int, pages: Int) {
        self.id = UUID()
        self.ownerId = ownerId
        self.book = book
        self.date = date
        self.minutes = minutes
        self.pages = pages
    }
}

@Model
final class Goal {
    var id: UUID
    var ownerId: String

    var rangeRaw: String   // "week" or "year"
    var targetPages: Int
    var startDate: Date

    init(ownerId: String, rangeRaw: String, targetPages: Int, startDate: Date) {
        self.id = UUID()
        self.ownerId = ownerId
        self.rangeRaw = rangeRaw
        self.targetPages = targetPages
        self.startDate = startDate
    }
}

@Model
final class Board {
    var id: UUID
    var ownerId: String
    var title: String
    var createdAt: Date

    // Relationship: a board contains books
    var books: [Book]

    init(ownerId: String, title: String, books: [Book] = []) {
        self.id = UUID()
        self.ownerId = ownerId
        self.title = title
        self.createdAt = Date()
        self.books = books
    }
}

@Model
final class UserProfile {
    var id: UUID
    var ownerId: String

    var displayName: String
    var username: String
    var photoData: Data?

    init(ownerId: String, displayName: String = "Reader", username: String = "reader") {
        self.id = UUID()
        self.ownerId = ownerId
        self.displayName = displayName
        self.username = username
        self.photoData = nil
    }
}

