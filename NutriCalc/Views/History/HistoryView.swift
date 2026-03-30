import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \LogEntry.date, order: .reverse) private var allEntries: [LogEntry]
    @AppStorage("showTimestamp") var showTimestamp = false

    private var todayKey: String { LogEntry.todayKey }

    /// Group entries by dayKey, excluding today, sorted descending
    private var groupedDays: [(key: String, entries: [LogEntry])] {
        var dict: [String: [LogEntry]] = [:]
        for entry in allEntries {
            let k = entry.dayKey
            if k == todayKey { continue }
            dict[k, default: []].append(entry)
        }
        return dict
            .map { (key: $0.key, entries: $0.value.sorted { $0.date < $1.date }) }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groupedDays.isEmpty {
                    ContentUnavailableView(
                        "No History Yet",
                        systemImage: "calendar",
                        description: Text("Past days will appear here once you start logging.")
                    )
                } else {
                    List {
                        ForEach(groupedDays, id: \.key) { day in
                            DaySection(dayKey: day.key, entries: day.entries, showTimestamp: showTimestamp)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
        }
    }
}

// MARK: - Day Section

private struct DaySection: View {
    let dayKey: String
    let entries: [LogEntry]
    let showTimestamp: Bool
    @State private var isExpanded = false

    private var totalCalories: Double { entries.reduce(0) { $0 + $1.totalCalories } }
    private var totalProtein:  Double { entries.reduce(0) { $0 + $1.totalProtein  } }
    private var totalCarbs:    Double { entries.reduce(0) { $0 + $1.totalCarbs    } }
    private var totalFat:      Double { entries.reduce(0) { $0 + $1.totalFat      } }

    private var displayDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dayKey) else { return dayKey }
        f.dateStyle = .full
        f.timeStyle = .none
        return f.string(from: date)
    }

    var body: some View {
        Section {
            // Collapsible header
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayDate).font(.headline).foregroundStyle(.primary)
                        Text("\(fmt(totalCalories)) kcal · P \(fmt(totalProtein))g · C \(fmt(totalCarbs))g · F \(fmt(totalFat))g")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            if isExpanded {
                ForEach(entries) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(entry.name.isEmpty
                                     ? (entry.isManual ? "Estimate" : entry.dishName)
                                     : entry.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                if entry.hasIncompleteMacros {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange).font(.caption2)
                                }
                            }
                            if !entry.name.isEmpty && !entry.isManual {
                                Text(entry.dishName).font(.caption).foregroundStyle(.secondary)
                            }
                            Text("\(fmt(entry.totalCalories)) kcal · P \(fmt(entry.totalProtein))g · C \(fmt(entry.totalCarbs))g · F \(fmt(entry.totalFat))g")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if showTimestamp {
                            Text(entry.date, style: .time)
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        v >= 100 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
