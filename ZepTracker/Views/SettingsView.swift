import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.pounds.rawValue
    @Query(sort: \LogEntry.date) private var entries: [LogEntry]

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight", selection: $unitRaw) {
                        ForEach(WeightUnit.allCases) { u in
                            Text(u.name).tag(u.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ShareLink(
                        item: CSVFile(text: CSVExport.make(entries: entries, unit: unit)),
                        preview: SharePreview("Zepbound log (\(entries.count) entries)")
                    ) {
                        Label("Export as CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Everything lives on this iPhone only — nothing is uploaded anywhere. Export a CSV now and then so you have a copy.")
                }

                Section {
                    LabeledContent("Entries", value: "\(entries.count)")
                    if let first = entries.first {
                        LabeledContent("Tracking since",
                                       value: first.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
