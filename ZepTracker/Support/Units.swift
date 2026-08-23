import Foundation
import SwiftUI

enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds, kilograms
    var id: String { rawValue }

    var short: String { self == .pounds ? "lb" : "kg" }
    var name: String { self == .pounds ? "Pounds" : "Kilograms" }

    func fromKg(_ kg: Double) -> Double { self == .pounds ? kg * 2.2046226218 : kg }
    func toKg(_ value: Double) -> Double { self == .pounds ? value / 2.2046226218 : value }

    /// e.g. "184.2 lb"
    func format(kg: Double, includeUnit: Bool = true) -> String {
        let v = fromKg(kg)
        let n = String(format: "%.1f", v)
        return includeUnit ? "\(n) \(short)" : n
    }

    /// Signed change, e.g. "-12.4 lb"
    func formatDelta(kg: Double) -> String {
        let v = fromKg(kg)
        let sign = v > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", v)) \(short)"
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    var relativeDayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInYesterday(self) { return "Yesterday" }
        return formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}
