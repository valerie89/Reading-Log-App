//
//  BoardDetailView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/15/26.
//

import SwiftUI
import SwiftData

struct BoardDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var board: Board
    let myBooks: [Book]

    @State private var showEditBooks = false
    @State private var showRename = false
    @State private var newTitle = ""

    var body: some View {
        ZStack {
            Color("BrandGreen").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {

                    Text(board.title)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    HStack(spacing: 10) {
                        Button {
                            newTitle = board.title
                            showRename = true
                        } label: {
                            Text("Rename")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.14)))
                        }

                        Button {
                            showEditBooks = true
                        } label: {
                            Text("Edit books")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color.white.opacity(0.14)))
                        }

                        Spacer()
                    }

                    if board.books.isEmpty {
                        Text("No books yet.")
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.top, 10)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(board.books) { b in
                                ProfileBookTile(book: b)
                            }
                        }
                        .padding(.top, 6)
                    }

                    Spacer(minLength: 28)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    modelContext.delete(board)
                    try? modelContext.save()
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showEditBooks) {
            EditBoardBooksSheet(board: board, myBooks: myBooks)
                .presentationDetents([.medium, .large])
        }
        .alert("Rename board", isPresented: $showRename) {
            TextField("Board title", text: $newTitle)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let t = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                board.title = t.isEmpty ? "Untitled" : t
                try? modelContext.save()
            }
        }
    }
}
