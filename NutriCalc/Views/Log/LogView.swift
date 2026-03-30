import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LogEntry.date, order: .reverse) private var allEntries: [LogEntry]
    @AppStorage("showTimestamp") var showTimestamp = false

    @State private var showingAddEntry = false
    @State private var showingGoals = false
    @State private var showingSettings = false
    @State private var editingEntry: LogEntry? = nil

    private var todayEntries: [LogEntry] {
        let key = LogEntry.todayKey
        return allEntries.filter { $0.dayKey == key }.sorted { $0.date < $1.date }
    }

    private var totalCalories: Double { todayEntries.reduce(0) { $0 + $1.totalCalories } }
    private var totalProtein:  Double { todayEntries.reduce(0) { $0 + $1.totalProtein  } }
    private var totalCarbs:    Double { todayEntries.reduce(0) { $0 + $1.totalCarbs    } }
    private var totalFat:      Double { todayEntries.reduce(0) { $0 + $1.totalFat      } }

    var body: some View {
        NavigationStack {
            List {
                // Dashboard pinned as first section (no header chrome)
                Section {
                    MacroDashboard(
                        calories: totalCalories,
                        protein:  totalProtein,
                        carbs:    totalCarbs,
                        fat:      totalFat
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Today's entries
                Section {
                    if todayEntries.isEmpty {
                        ContentUnavailableView(
                            "No Entries Yet",
                            systemImage: "fork.knife.circle",
                            description: Text("Tap + to log your first meal.")
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(todayEntries) { entry in
                            LogEntryRow(entry: entry, showTimestamp: showTimestamp)
                                .contentShape(Rectangle())
                                .onTapGesture { editingEntry = entry }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        modelContext.delete(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                } header: {
                    HStack {
                        Text("Today")
                        Spacer()
                        Button {
                            showingGoals = true
                        } label: {
                            Label("Goals", systemImage: "target")
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddEntry = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                NavigationStack { LogEntryFormView(entry: nil) }
            }
            .sheet(item: $editingEntry) { entry in
                NavigationStack { LogEntryFormView(entry: entry) }
            }
            .sheet(isPresented: $showingGoals) {
                GoalSettingsView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry
    let showTimestamp: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.name.isEmpty
                         ? (entry.isManual ? "Estimate" : entry.dishName)
                         : entry.name)
                        .font(.headline)
                        .lineLimit(1)

                    if entry.hasIncompleteMacros {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                if !entry.name.isEmpty && !entry.isManual {
                    Text(entry.dishName).font(.caption).foregroundStyle(.secondary)
                }

                Text("\(fmt(entry.totalCalories)) kcal · P \(fmt(entry.totalProtein))g · C \(fmt(entry.totalCarbs))g · F \(fmt(entry.totalFat))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showTimestamp {
                Text(Self.timeFormatter.string(from: entry.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func fmt(_ v: Double) -> String {
        v >= 100 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
