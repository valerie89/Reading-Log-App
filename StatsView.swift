//
//  StatsView.swift
//  ReadingLog
//
//  Created by Valerie Pena on 1/5/26.
//

import SwiftUI
import SwiftData

struct StatsView: View {

    enum Range: String, CaseIterable, Identifiable {
        case week = "Week"
        case year = "Year"
        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var session: SessionManager

    @Query(sort: \ReadingSession.date, order: .reverse) private var allSessions: [ReadingSession]
    @Query(sort: \Goal.startDate, order: .reverse) private var allGoals: [Goal]
    @Query(sort: \Book.createdAt, order: .reverse) private var allBooks: [Book]

    @State private var range: Range = .week
    @State private var showGoalSheet = false
    @State private var goalDraft: Int = 0

    private var ownerId: String { session.userId ?? "NO_USER" }
    private var cal: Calendar { .current }

    private var weekStart: Date {
        cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var yearStart: Date {
        cal.dateInterval(of: .year, for: Date())?.start ?? Date()
    }

    private var sessionsForOwner: [ReadingSession] {
        allSessions.filter { $0.ownerId == ownerId }
    }

    private var goalsForOwner: [Goal] {
        allGoals.filter { $0.ownerId == ownerId }
    }

    private var myReadingBooks: [Book] {
        allBooks
            .filter { $0.ownerId == ownerId }
            .filter { $0.statusRaw == LibraryView.LibraryTab.reading.rawValue }
            .sorted { (a: Book, b: Book) -> Bool in a.createdAt > b.createdAt }
    }

    private var weekSessions: [ReadingSession] { sessionsForOwner.filter { $0.date >= weekStart } }
    private var yearSessions: [ReadingSession] { sessionsForOwner.filter { $0.date >= yearStart } }

    private var pagesThisWeek: Int { weekSessions.reduce(0) { $0 + $1.pages } }
    private var minutesThisWeek: Int { weekSessions.reduce(0) { $0 + $1.minutes } }
    private var pagesThisYear: Int { yearSessions.reduce(0) { $0 + $1.pages } }
    private var minutesThisYear: Int { yearSessions.reduce(0) { $0 + $1.minutes } }

    // Sessions = number of DAYS with any logged reading
    private var sessionsCountThisWeek: Int {
        let days = weekSessions
            .filter { $0.pages > 0 || $0.minutes > 0 }
            .map { cal.startOfDay(for: $0.date) }
        return Set(days).count
    }

    private var sessionsCountThisYear: Int {
        let days = yearSessions
            .filter { $0.pages > 0 || $0.minutes > 0 }
            .map { cal.startOfDay(for: $0.date) }
        return Set(days).count
    }

    private var weekGoal: Goal? { goalsForOwner.first(where: { $0.rangeRaw == "week" }) }
    private var yearGoal: Goal? { goalsForOwner.first(where: { $0.rangeRaw == "year" }) }

    private var activeGoalPages: Int {
        switch range {
        case .week: return weekGoal?.targetPages ?? 0
        case .year: return yearGoal?.targetPages ?? 0
        }
    }

    private var activePagesRead: Int {
        switch range {
        case .week: return pagesThisWeek
        case .year: return pagesThisYear
        }
    }

    private var activeMinutes: Int {
        switch range {
        case .week: return minutesThisWeek
        case .year: return minutesThisYear
        }
    }

    private var activeSessionsCount: Int {
        switch range {
        case .week: return sessionsCountThisWeek
        case .year: return sessionsCountThisYear
        }
    }

    private var progress: Double {
        guard activeGoalPages > 0 else { return 0 }
        return min(Double(activePagesRead) / Double(activeGoalPages), 1.0)
    }

    private var subtitleText: String {
        activeGoalPages == 0 ? "No goal set yet" : "\(activePagesRead) of \(activeGoalPages) pages"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stats")
                        .font(.system(size: 38, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)

                    Picker("", selection: $range) {
                        ForEach(Range.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // Goal card
                StatsGoalRingCard(
                    titleTop: (range == .week) ? "This week" : "This year",
                    title: "Reading Goal",
                    subtitle: subtitleText,
                    progress: progress,
                    actionTitle: (activeGoalPages == 0) ? "Set goal" : "Edit goal"
                ) {
                    goalDraft = max(activeGoalPages, 0)
                    showGoalSheet = true
                }
                .padding(.horizontal, 16)

                // Weekly logging card
                ReadingLogWeekCard(
                    ownerId: ownerId,
                    weekStart: weekStart,
                    sessionsForOwner: sessionsForOwner,
                    readingBooks: myReadingBooks
                )
                .padding(.horizontal, 16)

                // Stat boxes
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if range == .week {
                        StatsStatCard(label: "Pages this week", value: "\(pagesThisWeek)")
                        StatsStatCard(label: "Goal", value: "\(activeGoalPages)")
                        StatsStatCard(label: "Sessions", value: "\(activeSessionsCount)")
                        StatsStatCard(label: "Minutes", value: "\(minutesThisWeek)")
                    } else {
                        StatsStatCard(label: "Pages this year", value: "\(pagesThisYear)")
                        StatsStatCard(label: "Goal", value: "\(activeGoalPages)")
                        StatsStatCard(label: "Sessions", value: "\(activeSessionsCount)")
                        StatsStatCard(label: "Minutes", value: "\(minutesThisYear)")
                    }
                }
                .padding(.horizontal, 16)

                // Streak heatmap
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reading streaks")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)

                    StatsHeatmapStreakView(
                        ownerId: ownerId,
                        sessionsForOwner: sessionsForOwner
                    )

                    Text("Consistency over the year — logs fill the map automatically.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer(minLength: 18)
            }
            .padding(.top, 12)
        }
        .background(Color("BrandGreen"))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showGoalSheet) {
            StatsGoalEditorSheet(
                title: (range == .week) ? "Weekly Goal" : "Yearly Goal",
                pages: $goalDraft
            ) {
                saveGoal(range: range, pages: goalDraft)
            }
            .presentationDetents([.medium])
        }
    }

    private func saveGoal(range: Range, pages: Int) {
        let cleaned = max(pages, 0)
        let key = (range == .week) ? "week" : "year"
        let start = (range == .week) ? weekStart : yearStart

        if let existing = goalsForOwner.first(where: { $0.rangeRaw == key }) {
            existing.targetPages = cleaned
            existing.startDate = start
        } else {
            let g = Goal(ownerId: ownerId, rangeRaw: key, targetPages: cleaned, startDate: start)
            modelContext.insert(g)
        }

        try? modelContext.save()
    }
}

// MARK: - Prefixed helper views (prevents collisions)

private struct StatsGoalRingCard: View {
    let titleTop: String
    let title: String
    let subtitle: String
    let progress: Double
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(titleTop)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Button(actionTitle, action: onAction)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.top, 4)
                    .foregroundStyle(Color("BrandGreen"))
            }

            Spacer()

            // Uses your shared ring
            ProgressRing(progress: progress)
                .frame(width: 82, height: 82)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(.systemBackground)))
    }
}

private struct StatsStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .serif))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
    }
}

private struct StatsHeatmapStreakView: View {
    let ownerId: String
    let sessionsForOwner: [ReadingSession]

    private let rows = 7
    private let cols = 26
    private let gap: CGFloat = 4
    private let innerPadding: CGFloat = 12
    private var cal: Calendar { .current }

    private var gridStart: Date {
        let start = cal.date(byAdding: .weekOfYear, value: -(cols - 1), to: Date()) ?? Date()
        return cal.dateInterval(of: .weekOfYear, for: start)?.start ?? start
    }

    private var activeDays: Set<Date> {
        let days = sessionsForOwner
            .filter { $0.ownerId == ownerId && ($0.pages > 0 || $0.minutes > 0) }
            .map { cal.startOfDay(for: $0.date) }
        return Set(days)
    }

    private func dateForCell(row: Int, col: Int) -> Date {
        let weekDate = cal.date(byAdding: .weekOfYear, value: col, to: gridStart) ?? gridStart
        let dayDate = cal.date(byAdding: .day, value: row, to: weekDate) ?? weekDate
        return cal.startOfDay(for: dayDate)
    }

    private func isFilled(row: Int, col: Int) -> Bool {
        activeDays.contains(dateForCell(row: row, col: col))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                Text("Jan"); Spacer()
                Text("Mar"); Spacer()
                Text("May"); Spacer()
                Text("Jul"); Spacer()
                Text("Sep"); Spacer()
                Text("Nov"); Spacer()
                Text("Dec")
            }
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 6)

            GeometryReader { geo in
                let available = geo.size.width - (innerPadding * 2)
                let cell = floor((available - (gap * CGFloat(cols - 1))) / CGFloat(cols))

                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: gap) {
                            ForEach(0..<cols, id: \.self) { c in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(isFilled(row: r, col: c) ? Color.white.opacity(0.9) : Color.white.opacity(0.18))
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
                .padding(innerPadding)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.12)))
            }
            .frame(height: 150)
        }
    }
}

private struct StatsGoalEditorSheet: View {
    let title: String
    @Binding var pages: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Pages: \(pages)", value: $pages, in: 0...10_000, step: 10)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Weekly Mini Calendar Log

private struct ReadingLogWeekCard: View {
    @Environment(\.modelContext) private var modelContext

    let ownerId: String
    let weekStart: Date
    let sessionsForOwner: [ReadingSession]
    let readingBooks: [Book]

    @State private var selectedDay: Date? = nil
    @State private var showSheet = false

    private var cal: Calendar { .current }

    private var weekDays: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func sessionsForDay(_ day: Date) -> [ReadingSession] {
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start

        return sessionsForOwner
            .filter { $0.ownerId == ownerId && $0.date >= start && $0.date < end }
            .sorted { (a: ReadingSession, b: ReadingSession) -> Bool in a.date > b.date }
    }

    private func isLogged(_ day: Date) -> Bool {
        sessionsForDay(day).contains { $0.pages > 0 || $0.minutes > 0 }
    }

    private func weekdayLetter(_ day: Date) -> String {
        let idx = cal.component(.weekday, from: day) // 1 = Sunday
        switch idx {
        case 1: return "S"
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "T"
        case 6: return "F"
        case 7: return "S"
        default: return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading log (This week)")
                .font(.system(size: 18, weight: .semibold, design: .serif))

            HStack(spacing: 10) {
                ForEach(weekDays, id: \.self) { day in
                    let filled = isLogged(day)

                    VStack(spacing: 6) {
                        Text(weekdayLetter(day))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Button {
                            selectedDay = day
                            showSheet = true
                        } label: {
                            Circle()
                                .fill(filled ? Color("BrandGreen") : Color(.systemGray5))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Text("\(cal.component(.day, from: day))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(filled ? Color.white : Color.primary)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("Tap a day to log multiple sessions (different books is okay).")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)))
        .sheet(isPresented: $showSheet) {
            if let day = selectedDay {
                DaySessionsSheet(
                    ownerId: ownerId,
                    day: day,
                    daySessions: sessionsForDay(day),
                    readingBooks: readingBooks
                )
            }
        }
    }
}

private struct DaySessionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let ownerId: String
    let day: Date
    let daySessions: [ReadingSession]
    let readingBooks: [Book]

    @State private var showNewSession = false
    @State private var editingSession: ReadingSession? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Logged sessions") {
                    if daySessions.isEmpty {
                        Text("No sessions logged for this day yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(daySessions) { s in
                            Button { editingSession = s } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(s.book?.title ?? "No book selected")
                                            .font(.system(size: 16, weight: .semibold))
                                            .lineLimit(1)

                                        Text("\(s.pages) pages • \(s.minutes) minutes")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Button { showNewSession = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add another session")
                        }
                        .foregroundStyle(Color("BrandGreen"))
                    }
                }
            }
            .navigationTitle(day.formatted(date: .abbreviated, time: .omitted))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showNewSession) {
                EditSessionSheet(
                    mode: .new,
                    ownerId: ownerId,
                    day: day,
                    session: nil,
                    readingBooks: readingBooks
                )
                .presentationDetents([.medium])
            }
            .sheet(item: $editingSession) { s in
                EditSessionSheet(
                    mode: .edit,
                    ownerId: ownerId,
                    day: day,
                    session: s,
                    readingBooks: readingBooks
                )
                .presentationDetents([.medium])
            }
        }
    }
}

private struct EditSessionSheet: View {
    enum Mode { case new, edit }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    let ownerId: String
    let day: Date
    let session: ReadingSession?
    let readingBooks: [Book]

    @State private var pages: Int = 0
    @State private var minutes: Int = 0
    @State private var selectedBookID: PersistentIdentifier? = nil

    private var selectedBook: Book? {
        guard let selectedBookID else { return nil }
        return readingBooks.first { $0.persistentModelID == selectedBookID }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Book") {
                    if readingBooks.isEmpty {
                        Text("No books in Currently Reading.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Reading", selection: $selectedBookID) {
                            Text("None").tag(Optional<PersistentIdentifier>.none)
                            ForEach(readingBooks, id: \.persistentModelID) { b in
                                Text(b.title).tag(Optional(b.persistentModelID))
                            }
                        }
                    }
                }

                Section("Progress") {
                    Stepper("Pages: \(pages)", value: $pages, in: 0...2000, step: 1)
                    Stepper("Minutes: \(minutes)", value: $minutes, in: 0...1440, step: 5)
                }
            }
            .navigationTitle(mode == .new ? "Add session" : "Edit session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                }
            }
            .onAppear {
                if let s = session {
                    pages = s.pages
                    minutes = s.minutes
                    selectedBookID = s.book?.persistentModelID
                } else {
                    selectedBookID = readingBooks.first?.persistentModelID
                }
            }
        }
    }

    private func save() {
        let p = max(pages, 0)
        let m = max(minutes, 0)

        if let s = session {
            s.ownerId = ownerId
            s.date = day
            s.pages = p
            s.minutes = m
            s.book = selectedBook
        } else {
            let s = ReadingSession(ownerId: ownerId, book: selectedBook, date: day, minutes: m, pages: p)
            modelContext.insert(s)
        }

        try? modelContext.save()
    }
}
