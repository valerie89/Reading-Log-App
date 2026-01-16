//
//  LibraryView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/2/26.
//

import SwiftUI
import SwiftData

// MARK: - Text Cleanup (fixes “sloppy” summary formatting)

private func cleanSummaryText(_ s: String) -> String {
    s
        .replacingOccurrences(of: "\u{00a0}", with: " ")
        .replacingOccurrences(of: "\r", with: "\n")

        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    
        .replacingOccurrences(of: "  ", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Library View

struct LibraryView: View {

    enum LibraryTab: String, CaseIterable, Identifiable {
        case reading, wishlist, finished, dnf
        var id: String { rawValue }
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case recent = "Recent"
        case mostLiked = "Most Liked"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var session: SessionManager
    @Query private var allBooks: [Book]

    @State private var selectedTab: LibraryTab = .reading
    @State private var sortMode: SortMode = .recent

    // API search state (Google Books)
    @State private var searchText = ""
    @State private var apiResults: [GoogleBook] = []
    @State private var isSearchingAPI = false
    @State private var apiError: String? = nil

    // debounce task so we don’t call API every keystroke
    @State private var searchTask: Task<Void, Never>? = nil

    // manual add sheet
    @State private var showingManualAdd = false

    private var userId: String { session.userId ?? "NO_USER" }

    private var sectionTitle: String {
        switch selectedTab {
        case .reading: return "Currently Reading"
        case .wishlist: return "Wishlist"
        case .finished: return "Finished"
        case .dnf: return "Didn't Finish"
        }
    }

    // Saved books for the selected shelf
    private var shelfBooks: [Book] {
        let base = allBooks
            .filter { $0.ownerId == userId }
            .filter { $0.statusRaw == selectedTab.rawValue }

        switch sortMode {
        case .recent:
            return base.sorted { $0.createdAt > $1.createdAt }
        case .mostLiked:
            return base.sorted {
                if $0.rating != $1.rating { return $0.rating > $1.rating }
                return $0.createdAt > $1.createdAt
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // Title + manual add button
                HStack {
                    Text("Library")
                        .font(.system(size: 44, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)

                    Spacer()

                    Button { showingManualAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color("BrandGreen"))
                            .accessibilityLabel("Add book")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                shelfChips

                // Only show Google Books search in Currently Reading
                if selectedTab == .reading {
                    searchAndSortRow
                } else {
                    sortOnlyRow
                }

                // API Results appear only when searchText is not empty
                if isShowingAPIResults {
                    apiResultsSection
                        .padding(.horizontal)
                } else {
                    Text(sectionTitle)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if shelfBooks.isEmpty {
                        emptyStateCard
                            .padding(.horizontal)
                    } else {
                        shelfList
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color("BrandGreen").ignoresSafeArea())
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingManualAdd) {
            ManualAddBookSheet { title, author in
                addManualBookToShelf(title: title, author: author)
            }
        }
    }


    // MARK: - Derived state

    private var isShowingAPIResults: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - UI Pieces

    private var shelfChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LibraryTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                        if tab != .reading {
                            clearAPISearch()
                        }
                    } label: {
                        Text(label(for: tab))
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? Color(.systemGray6) : .white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func label(for tab: LibraryTab) -> String {
        switch tab {
        case .reading: return "Currently"
        case .wishlist: return "Wishlist"
        case .finished: return "Finished"
        case .dnf: return "Didn't Finish"
        }
    }

    private var sortOnlyRow: some View {
        HStack {
            Spacer()
            sortMenu
        }
        .padding(.horizontal)
    }

    private var searchAndSortRow: some View {
        HStack(spacing: 10) {

            // Google Books Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search Google Books", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        runDebouncedAPISearch(newValue)
                    }
                    .accessibilityLabel("Search Google Books")

                if !searchText.isEmpty {
                    Button { clearAPISearch() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )

            sortMenu
        }
        .padding(.horizontal)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sortMode) {
                ForEach(SortMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(sortMode.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("BrandGreen"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .accessibilityLabel("Sort")
        .accessibilityValue(sortMode.rawValue)
    }

    private var apiResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Search Results")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if isSearchingAPI {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(Color.white.opacity(0.9))
                }
            }

            if let apiError {
                Text(apiError)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
            }

            if apiResults.isEmpty && !isSearchingAPI && apiError == nil {
                Text("Type to search Google Books.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(apiResults) { g in
                        Button {
                            addGoogleBookToShelf(g)
                        } label: {
                            GoogleResultRow(book: g)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 64)
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No books here yet.")
                .font(.system(size: 16, weight: .semibold))

            Text(emptyStateMessage)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .reading:
            return "Search above to add a book to your reading list."
        case .wishlist:
            return "Add books you want to read later."
        case .finished:
            return "Books you finish will appear here."
        case .dnf:
            return "Books you stop reading will appear here."
        }
    }

    private var shelfList: some View {
        VStack(spacing: 0) {
            ForEach(shelfBooks) { book in
                NavigationLink {
                    BookDetailView(book: book)
                } label: {
                    BookRow(
                        book: book,
                        onRate: { newRating in
                            book.rating = newRating
                            try? context.save()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 74)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func clearAPISearch() {
        searchText = ""
        apiResults = []
        apiError = nil
        isSearchingAPI = false
        searchTask?.cancel()
        searchTask = nil
    }

    // MARK: - API Search

    private func runDebouncedAPISearch(_ text: String) {
        searchTask?.cancel()

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            apiResults = []
            apiError = nil
            isSearchingAPI = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)

            await MainActor.run {
                isSearchingAPI = true
                apiError = nil
            }

            do {
                let results = try await GoogleBooksAPI.search(query: trimmed)
                await MainActor.run {
                    self.apiResults = results
                    self.isSearchingAPI = false
                    if results.isEmpty {
                        self.apiError = "No results found."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSearchingAPI = false
                    self.apiError = "Search failed. Try again."
                }
            }
        }
    }

    // MARK: - Add from Google results

    private func addGoogleBookToShelf(_ selected: GoogleBook) {
        guard session.userId != nil else { return }

        // prevent duplicates per user (by Google volume ID)
        let alreadyExists = allBooks.contains {
            $0.ownerId == userId && $0.googleVolumeId == selected.id
        }
        if alreadyExists { return }

        let newBook = Book(
            ownerId: userId,
            googleVolumeId: selected.id,
            title: selected.title,
            authors: selected.authors,
            coverURL: selected.thumbnailURL?.absoluteString,
            statusRaw: LibraryTab.reading.rawValue
        )

        context.insert(newBook)
        try? context.save()

        clearAPISearch()
    }

    // MARK: - Manual add

    private func addManualBookToShelf(title: String, author: String) {
        guard session.userId != nil else { return }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)

        let manualId = "MANUAL-\(UUID().uuidString)"

        let newBook = Book(
            ownerId: userId,
            googleVolumeId: manualId,
            title: cleanTitle.isEmpty ? "Untitled" : cleanTitle,
            authors: cleanAuthor.isEmpty ? "Unknown author" : cleanAuthor,
            coverURL: nil,
            statusRaw: LibraryTab.reading.rawValue
        )

        context.insert(newBook)
        try? context.save()
    }
}

// MARK: - Rows

private struct BookRow: View {
    let book: Book
    let onRate: (Int) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            AsyncImage(url: coverURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(Image(systemName: "book.closed"))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(book.authors)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                RatingStars(rating: book.rating, onSet: onRate)
            }

            Spacer()
        }
    }

    private var coverURL: URL? {
        guard let s = book.coverURL else { return nil }
        return URL(string: s)
    }
}

private struct GoogleResultRow: View {
    let book: GoogleBook

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: book.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5))
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .overlay(Image(systemName: "book.closed"))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 44, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(book.authors)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("Add")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Detail View

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var book: Book

    @State private var summaryText: String? = nil
    @State private var isLoadingSummary = false
    @State private var isSummaryExpanded = false

    @State private var keyQuotes: [String] = [
        "Never outshine the master.",
        "Strike the shepherd and the sheep will scatter."
    ]

    @State private var readerReviews: [ReaderReview] = [
        .init(source: "New York Magazine", rating: 5, quote: "A guidebook for the ruthless and ambitious."),
        .init(source: "The Times", rating: 4, quote: "An essential read for understanding power dynamics.")
    ]

    private var isFinished: Bool {
        book.statusRaw == LibraryView.LibraryTab.finished.rawValue
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                topBar

                // Cover + info
                VStack(spacing: 10) {
                    AsyncImage(url: coverURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.12))
                        case .success(let img):
                            img.resizable().scaledToFill()
                        case .failure:
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.12))
                                .overlay(Image(systemName: "book.closed").foregroundStyle(.white.opacity(0.9)))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 165, height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 12)

                    Text(book.title)
                        .font(.system(size: 28, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal)

                    Text(book.authors)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    RatingStars(rating: book.rating) { newRating in
                        book.rating = newRating
                        try? context.save()
                    }
                }
                .padding(.top, 2)

                finishedPill

                summaryGlassCard

                bottomTwoCards

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 30)
            .padding(.top, 10)
        }
        .background(
            Color("BrandGreen")
                .ignoresSafeArea(.container, edges: [.top, .leading, .trailing])
        )
        .navigationBarBackButtonHidden(true)
        .task { await loadSummaryIfNeeded() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text("Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 42, height: 42)
                        .background(Color.black.opacity(0.22))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Finished pill (clear selected vs not selected)

    private var finishedPill: some View {
        Button { toggleFinished() } label: {
            HStack(spacing: 8) {
                Text(isFinished ? "Finished" : "Mark as Finished")
                    .font(.system(size: 17, weight: .semibold))

                if isFinished {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(isFinished ? Color.black.opacity(0.85) : Color.white.opacity(0.92))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isFinished {
                        Color(red: 0.93, green: 0.74, blue: 0.22)
                    } else {
                        Color.white.opacity(0.14)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isFinished ? Color.white.opacity(0.15) : Color.white.opacity(0.18),
                    lineWidth: 1
                )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Summary card (cleaned text + nicer spacing)

    private var summaryGlassCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                if isLoadingSummary {
                    ProgressView().scaleEffect(0.9).tint(Color.white.opacity(0.9))
                }
            }

            if let summaryText, !summaryText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(summaryText)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineSpacing(5)
                        .lineLimit(isSummaryExpanded ? nil : 6)

                    Text("Source: Google Books")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))

                    Button {
                        withAnimation(.easeInOut) {
                            isSummaryExpanded.toggle()
                        }
                    } label: {
                        Text(isSummaryExpanded ? "Read less" : "Read more")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("No summary available.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Two half cards (Key Quotes + Reader Reviews)

    private var bottomTwoCards: some View {
        HStack(spacing: 12) {
            keyQuotesCard
            readerReviewsCard
        }
    }

    private var keyQuotesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .foregroundStyle(Color(red: 0.93, green: 0.74, blue: 0.22))
                Text("Key Quotes")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.92))
            }

            if keyQuotes.isEmpty {
                Text("No quotes saved yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(keyQuotes.prefix(2).enumerated()), id: \.offset) { _, q in
                        Text("“\(q)”")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundStyle(.white.opacity(0.90))
                            .lineLimit(3)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var readerReviewsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reader Reviews")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(.white.opacity(0.92))

            if readerReviews.isEmpty {
                Text("No reviews yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(readerReviews.prefix(2)) { r in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                StarRow(count: r.rating)
                                Text("– \(r.source)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.70))
                                    .lineLimit(1)
                            }

                            Text("“\(r.quote)”")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.88))
                                .lineLimit(3)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Logic

    private func toggleFinished() {
        book.statusRaw = isFinished
        ? LibraryView.LibraryTab.reading.rawValue
        : LibraryView.LibraryTab.finished.rawValue

        try? context.save()
        if book.statusRaw == LibraryView.LibraryTab.finished.rawValue {
            dismiss()
        }
    }

    private var coverURL: URL? {
        guard let s = book.coverURL else { return nil }
        return URL(string: s)
    }

    private func loadSummaryIfNeeded() async {
        if book.googleVolumeId.hasPrefix("MANUAL-") { return }
        if summaryText != nil { return }

        isLoadingSummary = true
        defer { isLoadingSummary = false }

        do {
            let html = try await GoogleBooksAPI.fetchSummary(volumeId: book.googleVolumeId)
            guard let html else {
                summaryText = nil
                return
            }

            guard let data = html.data(using: .utf8) else {
                summaryText = nil
                return
            }

            let ns = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )

            let raw = ns?.string ?? ""
            let cleaned = cleanSummaryText(raw)
            summaryText = cleaned.isEmpty ? nil : cleaned

        } catch {
            summaryText = nil
        }
    }
}

// MARK: - Reviews Model + Stars

private struct ReaderReview: Identifiable, Hashable {
    let id = UUID()
    let source: String
    let rating: Int   // 1...5
    let quote: String
}

private struct StarRow: View {
    let count: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<min(max(count, 0), 5), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.93, green: 0.74, blue: 0.22))
            }
        }
    }
}

// MARK: - Manual Add Sheet

private struct ManualAddBookSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""

    let onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Book info") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                }
            }
            .navigationTitle("Add Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, author)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Google Books API

struct GoogleBook: Identifiable, Hashable {
    let id: String
    let title: String
    let authors: String
    let thumbnailURL: URL?
}

enum GoogleBooksAPI {

    static func search(query: String) async throws -> [GoogleBook] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let q = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=\(q)&maxResults=20"
        guard let url = URL(string: urlString) else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(VolumesResponse.self, from: data)
        let items = decoded.items ?? []

        return items.compactMap { item in
            let info = item.volumeInfo
            let title = info.title ?? "Untitled"
            let authors = (info.authors ?? []).joined(separator: ", ")

            let thumb = info.imageLinks?.thumbnail
            let thumbURL = thumb.flatMap {
                URL(string: $0.replacingOccurrences(of: "http://", with: "https://"))
            }

            return GoogleBook(
                id: item.id ?? UUID().uuidString,
                title: title,
                authors: authors.isEmpty ? "Unknown author" : authors,
                thumbnailURL: thumbURL
            )
        }
    }

    static func fetchSummary(volumeId: String) async throws -> String? {
        let urlString = "https://www.googleapis.com/books/v1/volumes/\(volumeId)"
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(VolumeItem.self, from: data)
        return decoded.volumeInfo.description
    }

    // MARK: - Decoding structs

    private struct VolumesResponse: Decodable { let items: [VolumeItem]? }

    private struct VolumeItem: Decodable {
        let id: String?
        let volumeInfo: VolumeInfo
    }

    private struct VolumeInfo: Decodable {
        let title: String?
        let authors: [String]?
        let imageLinks: ImageLinks?
        let description: String?
    }

    private struct ImageLinks: Decodable { let thumbnail: String? }
}
