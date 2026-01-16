//
//  HomeView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var session: SessionManager

    @Query(sort: \Book.createdAt, order: .reverse) private var allBooks: [Book]
    @Query(sort: \ReadingSession.date, order: .reverse) private var allSessions: [ReadingSession]
    @Query(sort: \Goal.startDate, order: .reverse) private var allGoals: [Goal]

    // Trending
    @State private var isLoadingTrending = false
    @State private var trending: [GoogleBook] = []
    @State private var trendingError: String? = nil

    // Because you read
    @State private var isLoadingBecause = false
    @State private var becauseBooks: [GoogleBook] = []
    @State private var becauseError: String? = nil

    private var userId: String { session.userId ?? "NO_USER" }
    private var cal: Calendar { .current }

    private var myBooks: [Book] {
        allBooks.filter { $0.ownerId == userId }
    }

    private var myReading: [Book] {
        myBooks
            .filter { $0.statusRaw == LibraryView.LibraryTab.reading.rawValue }
            .sorted { (a: Book, b: Book) -> Bool in a.createdAt > b.createdAt }
    }

    private var myFinished: [Book] {
        myBooks
            .filter { $0.statusRaw == LibraryView.LibraryTab.finished.rawValue }
            .sorted { (a: Book, b: Book) -> Bool in a.createdAt > b.createdAt }
    }

    // Seed for “Because you read…”
    private var becauseSeed: Book? {
        // Prefer a recently finished seed (feels more stable),
        // otherwise fall back to current reading.
        if let finished = myFinished.first { return finished }
        return myReading.first
    }

    private var sessionsForOwner: [ReadingSession] {
        allSessions.filter { $0.ownerId == userId }
    }

    private var weekStart: Date {
        cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var weekSessions: [ReadingSession] {
        sessionsForOwner.filter { $0.date >= weekStart }
    }

    private var pagesThisWeek: Int { weekSessions.reduce(0) { $0 + $1.pages } }
    private var minutesThisWeek: Int { weekSessions.reduce(0) { $0 + $1.minutes } }

    private var sessionsCountThisWeek: Int {
        let days = weekSessions
            .filter { $0.pages > 0 || $0.minutes > 0 }
            .map { cal.startOfDay(for: $0.date) }
        return Set(days).count
    }

    private var weekGoal: Goal? {
        allGoals.first(where: { $0.ownerId == userId && $0.rangeRaw == "week" })
    }

    private var weekGoalPages: Int { weekGoal?.targetPages ?? 0 }

    private var weekProgress: Double {
        guard weekGoalPages > 0 else { return 0 }
        return min(Double(pagesThisWeek) / Double(weekGoalPages), 1.0)
    }

    private var greeting: String {
        let hour = cal.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandGreen").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        header

                        if !myReading.isEmpty {
                            continueReadingSection
                        } else {
                            emptyContinueReading
                        }

                        weeklySnapshotCard

                        trendingSection

                        becauseYouReadSection

                        if !myFinished.isEmpty {
                            recentlyFinishedSection
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)

            .toolbarBackground(Color("BrandGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)

            .task {
                await loadTrendingIfNeeded()
                await loadBecauseIfNeeded()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Home")
                .font(.system(size: 44, weight: .semibold, design: .serif))
                .foregroundStyle(.white)

            Text("\(greeting), \(session.userId ?? "reader").")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.80))

            Text("Your reading, gently tracked.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .padding(.horizontal)
    }

    // MARK: - Continue reading

    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Continue reading")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(myReading.prefix(10)) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            ContinueReadingCard(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }

    private var emptyContinueReading: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Continue reading")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal)

            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .frame(height: 92)
                .overlay(
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add a book to get started.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                        Text("Go to Explore to find books, then save them to your Library.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 16),
                    alignment: .leading
                )
                .padding(.horizontal)
        }
    }

    // MARK: - Weekly snapshot

    private var weeklySnapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This week")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Text("Weekly snapshot")
                        .font(.system(size: 22, weight: .semibold, design: .serif))

                    Text("\(pagesThisWeek) pages • \(minutesThisWeek) minutes • \(sessionsCountThisWeek) sessions")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ProgressRing(progress: weekProgress)
                    .frame(width: 74, height: 74)
            }

            if weekGoalPages == 0 {
                Text("Set a weekly goal in Stats to see progress here.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Text("\(pagesThisWeek) of \(weekGoalPages) pages")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Trending

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Trending right now")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                if isLoadingTrending {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(Color.white.opacity(0.9))
                }
            }
            .padding(.horizontal)

            if let trendingError {
                Text(trendingError)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.80))
                    .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if trending.isEmpty && !isLoadingTrending && trendingError == nil {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 108, height: 152)
                        }
                    } else {
                        ForEach(trending.prefix(12)) { g in
                            TrendingBookCard(book: g)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Because you read

    private var becauseYouReadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(becauseSeed != nil ? "Because you read \(becauseSeed!.title)" : "Because you read")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                if isLoadingBecause {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(Color.white.opacity(0.9))
                }
            }
            .padding(.horizontal)

            if let becauseError {
                Text(becauseError)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.80))
                    .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if becauseBooks.isEmpty && !isLoadingBecause && becauseError == nil {
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 108, height: 152)
                        }
                    } else {
                        ForEach(becauseBooks.prefix(12)) { g in
                            TrendingBookCard(book: g)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Recently finished

    private var recentlyFinishedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recently finished")
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(myFinished.prefix(10)) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            ContinueReadingCard(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Load trending

    private func loadTrendingIfNeeded() async {
        if !trending.isEmpty || isLoadingTrending { return }

        await MainActor.run {
            isLoadingTrending = true
            trendingError = nil
        }

        do {
            let queries = [
                "new york times best sellers fiction",
                "popular books",
                "award winning novels",
                "top rated fantasy books"
            ]

            let q = queries.randomElement() ?? "popular books"
            let books = try await GoogleBooksAPI.search(query: q)

            await MainActor.run {
                trending = books
                isLoadingTrending = false
                if books.isEmpty { trendingError = "No results right now." }
            }
        } catch {
            await MainActor.run {
                isLoadingTrending = false
                trendingError = "Couldn’t load trending books."
            }
        }
    }

    // MARK: - Load because you read

    private func loadBecauseIfNeeded() async {
        guard becauseBooks.isEmpty, !isLoadingBecause else { return }
        guard let seed = becauseSeed else {
            await MainActor.run {
                becauseError = "Add a book to Currently Reading or finish a book to get suggestions."
            }
            return
        }

        await MainActor.run {
            isLoadingBecause = true
            becauseError = nil
        }

        do {
            let firstAuthor = seed.authors
                .components(separatedBy: ",")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? seed.authors

            // Google Books supports query operators like inauthor:
            let query = "inauthor:\(firstAuthor)"
            let results = try await GoogleBooksAPI.search(query: query)

            let filtered = results.filter { $0.id != seed.googleVolumeId }

            await MainActor.run {
                becauseBooks = filtered
                isLoadingBecause = false
                if filtered.isEmpty { becauseError = "No suggestions right now." }
            }
        } catch {
            await MainActor.run {
                isLoadingBecause = false
                becauseError = "Couldn’t load suggestions."
            }
        }
    }
}

// MARK: - Cards

private struct ContinueReadingCard: View {
    let book: Book

    private var coverURL: URL? {
        guard let s = book.coverURL else { return nil }
        return URL(string: s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: coverURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.14))
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.14))
                        .overlay(Image(systemName: "book.closed").foregroundStyle(.white.opacity(0.9)))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 120, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)

            Text(book.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            Text(book.authors)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.70))
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
        }
    }
}

private struct TrendingBookCard: View {
    let book: GoogleBook

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: book.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.14))
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.14))
                        .overlay(Image(systemName: "book.closed").foregroundStyle(.white.opacity(0.9)))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 120, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)

            Text(book.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            Text(book.authors)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.70))
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
        }
    }
}
