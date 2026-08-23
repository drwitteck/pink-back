import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.pounds.rawValue
    @Query(sort: \LogEntry.date, order: .reverse) private var entries: [LogEntry]

    @State private var editing: LogEntry?
    @State private var showingSettings = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    private var todaysEntry: LogEntry? {
        entries.first { Calendar.current.isDateInToday($0.date) }
    }

    private var weighIns: [LogEntry] { entries.filter { $0.weightKg != nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    logCard
                    if !entries.isEmpty { recentSection }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Zep Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(item: $editing) { entry in
                EntryEditorView(entry: entry)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        VStack(spacing: 14) {
            if let latest = weighIns.first, let kg = latest.weightKg {
                Text(unit.format(kg: kg))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())

                Text("Last weigh-in \(latest.date.relativeDayLabel)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let start = weighIns.last?.weightKg, weighIns.count > 1 {
                    let delta = kg - start
                    HStack(spacing: 6) {
                        Image(systemName: delta <= 0 ? "arrow.down.right" : "arrow.up.right")
                        Text(unit.formatDelta(kg: delta))
                        Text("since \(weighIns.last!.date.formatted(.dateTime.month(.abbreviated).day()))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(delta <= 0 ? .teal : .orange)
                }
            } else {
                Image(systemName: "scalemass")
                    .font(.system(size: 34))
                    .foregroundStyle(.teal)
                Text("No weigh-ins yet")
                    .font(.headline)
                Text("Log your first entry to start the trend.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }

    private var logCard: some View {
        VStack(spacing: 12) {
            if let today = todaysEntry {
                HStack {
                    Text(Feeling.emoji(today.feeling)).font(.title)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logged today")
                            .font(.subheadline.weight(.semibold))
                        Text(todaySummary(today))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Button { editing = today } label: {
                    Text("Edit today's entry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                Button {
                    editing = LogEntry(feeling: lastFeeling)
                } label: {
                    Label("Log today", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(entries.prefix(5))) { entry in
                    Button { editing = entry } label: {
                        EntryRow(entry: entry, unit: unit)
                    }
                    .buttonStyle(.plain)

                    if entry.id != entries.prefix(5).last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        }
    }

    // MARK: - Helpers

    private var lastFeeling: Int { entries.first?.feeling ?? 3 }

    private func todaySummary(_ entry: LogEntry) -> String {
        var parts: [String] = [Feeling.label(entry.feeling)]
        if let kg = entry.weightKg { parts.append(unit.format(kg: kg)) }
        if entry.sideEffects.isEmpty {
            parts.append("no side effects")
        } else {
            parts.append("\(entry.sideEffects.count) side effect\(entry.sideEffects.count == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }
}

struct EntryRow: View {
    let entry: LogEntry
    let unit: WeightUnit

    var body: some View {
        HStack(spacing: 12) {
            Text(Feeling.emoji(entry.feeling))
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.date.relativeDayLabel)
                        .font(.subheadline.weight(.medium))
                    if entry.isInjectionDay {
                        Image(systemName: "syringe.fill")
                            .font(.caption2)
                            .foregroundStyle(.teal)
                    }
                }
                if !entry.sideEffects.isEmpty {
                    Text(entry.sideEffects.map(\.kind).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let kg = entry.weightKg {
                Text(unit.format(kg: kg))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .contentShape(.rect)
    }
}
