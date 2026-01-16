import SwiftUI

struct ProfileBookTile: View {
    let book: Book

    private var coverURL: URL? {
        guard let s = book.coverURL else { return nil }
        return URL(string: s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: coverURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.14))
                case .success(let img):
                    img.resizable().scaledToFill()
                case .failure:
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.14))
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundStyle(.white.opacity(0.9))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(book.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)

            Text(book.authors)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.70))
                .lineLimit(1)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}
