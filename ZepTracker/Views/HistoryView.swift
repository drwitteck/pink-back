import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.pounds.rawValue
    @Query(sort: \LogEntry.date, order: .reverse) private var entries: [LogEntry]
    @State private var editing: LogEntry?

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    private var months: [(key: Date, entries: [LogEntry])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            cal.date(from: cal.dateComponents([.year, .month], from: entry.date)) ?? entry.date
        }
        return grouped
            .map { (key: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No entries yet",
                        systemImage: "list.bullet",
                        description: Text("Everything you log shows up here.")
                    )
                } else {
                    List {
                        ForEach(months, id: \.key) { month in
                            Section(month.key.formatted(.dateTime.month(.wide).year())) {
                                ForEach(month.entries) { entry in
                                    Button { editing = entry } label: {
                                        EntryRow(entry: entry, unit: unit)
                                            .padding(.vertical, -8)
                                            .padding(.horizontal, -16)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    for index in offsets { context.delete(month.entries[index]) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editing = LogEntry(feeling: entries.first?.feeling ?? 3) } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editing) { EntryEditorView(entry: $0) }
        }
    }
}
