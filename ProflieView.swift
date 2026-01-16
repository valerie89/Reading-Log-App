//
//  ProfileView.swift
//  ReadingLog
//
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: SessionManager

    @Query(sort: \Book.createdAt, order: .reverse) private var allBooks: [Book]
    @Query(sort: \Board.createdAt, order: .reverse) private var allBoards: [Board]
    @Query private var allProfiles: [UserProfile]

    @State private var showCreateBoard = false

    private var userId: String { session.userId ?? "NO_USER" }

    private var myProfile: UserProfile? {
        allProfiles.first { $0.ownerId == userId }
    }

    private var myBooks: [Book] {
        allBooks.filter { $0.ownerId == userId }
    }

    private var myBoards: [Board] {
        allBoards.filter { $0.ownerId == userId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BrandGreen").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        header
                        boardsGrid
                        Spacer(minLength: 28)
                    }
                    .padding(.top, 10)
                }
                .onAppear {
                    // Ensure a profile exists for this user
                    if userId != "NO_USER", myProfile == nil {
                        let p = UserProfile(ownerId: userId, displayName: "Reader", username: "reader")
                        modelContext.insert(p)
                        try? modelContext.save()
                    }
                }

                // Floating Create button (Pinterest vibes)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateBoard = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Create")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.red))
                            .shadow(radius: 14)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 18)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("BrandGreen"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreateBoard) {
                CreateBoardSheet(ownerId: userId, books: myBooks) { title, selected in
                    let b = Board(ownerId: userId, title: title, books: selected)
                    modelContext.insert(b)
                    try? modelContext.save()
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 92, height: 92)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                )

            Text("Profile")
                .font(.system(size: 42, weight: .semibold, design: .serif))
                .foregroundStyle(.white)

            Text("@\(myProfile?.username ?? "reader")")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            HStack(spacing: 18) {
                statPill("\(myBooks.count)", "Books")
                statPill("\(myBoards.count)", "Boards")
            }

            Button {
                // TODO: hook to EditProfileView
            } label: {
                Text("Edit profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private func statPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Boards

    private var boardsGrid: some View {
        Group {
            if myBoards.isEmpty {
                emptyState(
                    title: "No boards yet",
                    subtitle: "Tap Create to organize your library into boards."
                )
                .padding(.top, 10)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(myBoards) { board in
                        NavigationLink {
                            BoardDetailView(board: board, myBooks: myBooks)
                        } label: {
                            BoardTile(board: board)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
        }
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.10))
                .frame(height: 140)
                .overlay(
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.8))
                )
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .padding(.horizontal)
    }
}

// MARK: - Board Tile + Preview

private struct BoardTile: View {
    let board: Board

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let preview = Array(board.books.prefix(4))

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.12))

                if preview.isEmpty {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                } else {
                    BoardPreviewGrid(books: preview)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .frame(height: 150)

            Text(board.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)

            Text("\(board.books.count) books")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

private struct BoardPreviewGrid: View {
    let books: [Book]

    private func url(_ book: Book) -> URL? {
        guard let s = book.coverURL else { return nil }
        return URL(string: s)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let cols = 2
            let rows = 2
            let cellW = (w - 6) / CGFloat(cols)
            let cellH = (h - 6) / CGFloat(rows)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    tile(for: books[safe: 0], w: cellW, h: cellH)
                    tile(for: books[safe: 1], w: cellW, h: cellH)
                }
                HStack(spacing: 6) {
                    tile(for: books[safe: 2], w: cellW, h: cellH)
                    tile(for: books[safe: 3], w: cellW, h: cellH)
                }
            }
        }
    }

    @ViewBuilder
    private func tile(for book: Book?, w: CGFloat, h: CGFloat) -> some View {
        if let book {
            AsyncImage(url: url(book)) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12))
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12))
                @unknown default:
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12))
                }
            }
            .frame(width: w, height: h)
            .clipped()
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.12))
                .frame(width: w, height: h)
        }
    }
}

// MARK: - Create Board Sheet

private struct CreateBoardSheet: View {
    @Environment(\.dismiss) private var dismiss

    let ownerId: String
    let books: [Book]
    let onCreate: (_ title: String, _ selected: [Book]) -> Void

    @State private var title: String = ""
    @State private var selectedIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Board name") {
                    TextField("e.g. Romance reads", text: $title)
                }

                Section("Add books") {
                    if books.isEmpty {
                        Text("No books in your library yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(books) { b in
                            Toggle(isOn: binding(for: b.id)) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(b.title).font(.system(size: 15, weight: .semibold))
                                    Text(b.authors).font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create board")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let picked = books.filter { selectedIds.contains($0.id) }
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCreate(t.isEmpty ? "Untitled" : t, picked)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedIds.isEmpty)
                }
            }
        }
    }

    private func binding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedIds.contains(id) },
            set: { isOn in
                if isOn { selectedIds.insert(id) } else { selectedIds.remove(id) }
            }
        )
    }
}

// Safe array indexing helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
