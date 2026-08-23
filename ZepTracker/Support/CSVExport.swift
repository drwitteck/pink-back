import Foundation
import CoreTransferable
import UniformTypeIdentifiers

/// A CSV snapshot of the whole log, for backup or handing to a doctor.
struct CSVFile: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName("zepbound-log.csv")
    }
}

enum CSVExport {
    static func make(entries: [LogEntry], unit: WeightUnit) -> String {
        var rows = ["date,weight_\(unit.short),feeling,feeling_label,injection,dose_mg,side_effects,notes"]
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            let weight = entry.weightKg.map { unit.format(kg: $0, includeUnit: false) } ?? ""
            let dose = entry.doseMg.map { String($0) } ?? ""
            let effects = entry.sideEffects
                .map { "\($0.kind) (\($0.severityLabel))" }
                .joined(separator: "; ")
            let fields = [
                df.string(from: entry.date),
                weight,
                String(entry.feeling),
                Feeling.label(entry.feeling),
                entry.isInjectionDay ? "yes" : "",
                dose,
                effects,
                entry.notes
            ]
            rows.append(fields.map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
