import SwiftUI
import SwiftData
import Charts

enum TrendRange: String, CaseIterable, Identifiable {
    case month = "30D", quarter = "90D", all = "All"
    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .month: return 30
        case .quarter: return 90
        case .all: return nil
        }
    }
}

struct TrendsView: View {
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.pounds.rawValue
    @Query(sort: \LogEntry.date) private var allEntries: [LogEntry]
    @State private var range: TrendRange = .quarter

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    private var entries: [LogEntry] {
        guard let days = range.days,
              let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date().startOfDay)
        else { return allEntries }
        return allEntries.filter { $0.date >= cutoff }
    }

    private var weighIns: [LogEntry] { entries.filter { $0.weightKg != nil } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Range", selection: $range) {
                        ForEach(TrendRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if allEntries.isEmpty {
                        emptyState
                    } else {
                        statsGrid
                        weightChart
                        feelingChart
                        sideEffectChart
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trends")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing to chart yet",
            systemImage: "chart.xyaxis.line",
            description: Text("Log a few days and your trends will show up here.")
        )
        .padding(.top, 60)
    }

    // MARK: - Stats

    private var statsGrid: some View {
        let kgs = weighIns.compactMap(\.weightKg)
        let feelings = entries.map(\.feeling)
        let change = (kgs.count > 1 && kgs.first != nil && kgs.last != nil) ? kgs.last! - kgs.first! : nil

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "Change",
                     value: change.map { unit.formatDelta(kg: $0) } ?? "—",
                     tint: (change ?? 0) <= 0 ? .teal : .orange)
            StatTile(title: "Lowest",
                     value: kgs.min().map { unit.format(kg: $0) } ?? "—",
                     tint: .teal)
            StatTile(title: "Avg feeling",
                     value: feelings.isEmpty ? "—" : String(format: "%.1f / 5", Double(feelings.reduce(0, +)) / Double(feelings.count)),
                     tint: .indigo)
            StatTile(title: "Days logged",
                     value: "\(entries.count)",
                     tint: .indigo)
        }
    }

    // MARK: - Charts

    private var weightChart: some View {
        ChartCard(title: "Weight", subtitle: weighIns.count < 2 ? "Needs at least two weigh-ins" : nil) {
            if weighIns.count >= 2 {
                Chart {
                    ForEach(weighIns) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", unit.fromKg(entry.weightKg ?? 0))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.teal)
                        .lineStyle(.init(lineWidth: 2.5))

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", unit.fromKg(entry.weightKg ?? 0))
                        )
                        .foregroundStyle(.teal)
                        .symbolSize(28)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 200)
            }
        }
    }

    private var feelingChart: some View {
        ChartCard(title: "How I felt", subtitle: nil) {
            Chart {
                ForEach(entries) { entry in
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Feeling", entry.feeling)
                    )
                    .foregroundStyle(feelingColor(entry.feeling))
                    .cornerRadius(3)
                }
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(position: .leading, values: [1, 3, 5]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) { Text(Feeling.label(v)) }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 160)
        }
    }

    private var sideEffectChart: some View {
        let counts = Dictionary(grouping: entries.flatMap(\.sideEffects), by: \.kind)
            .map { (kind: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(6)

        return ChartCard(title: "Side effects", subtitle: counts.isEmpty ? "None logged in this range" : nil) {
            if !counts.isEmpty {
                Chart {
                    ForEach(Array(counts), id: \.kind) { item in
                        BarMark(
                            x: .value("Days", item.count),
                            y: .value("Side effect", item.kind)
                        )
                        .foregroundStyle(.teal.gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(counts.count) * 34 + 16)
            }
        }
    }

    private func feelingColor(_ value: Int) -> Color {
        switch value {
        case 1: return .red.opacity(0.7)
        case 2: return .orange.opacity(0.8)
        case 3: return .yellow.opacity(0.85)
        case 4: return .teal.opacity(0.8)
        default: return .teal
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
    }
}
