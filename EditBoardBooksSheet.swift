//
//  EditBoardBooksSheet.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/15/26.
//

import SwiftUI
import SwiftData

struct EditBoardBooksSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var board: Board
    let myBooks: [Book]

    @State private var selectedIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                if myBooks.isEmpty {
                    Text("No books in your library yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(myBooks) { b in
                        Toggle(isOn: binding(for: b.id)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(b.title).font(.system(size: 15, weight: .semibold))
                                Text(b.authors).font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit books")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applySelection()
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedIds = Set(board.books.map { $0.id })
            }
        }
    }

    private func applySelection() {
        let picked = myBooks.filter { selectedIds.contains($0.id) }
        board.books = picked
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
