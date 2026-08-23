import Foundation
import SwiftData

@Model
final class LogEntry {
    var date: Date = Date()

    /// Stored canonically in kilograms; the UI converts for display.
    var weightKg: Double?

    /// 1 = rough, 5 = great.
    var feeling: Int = 3

    var sideEffects: [SideEffectLog] = []
    var notes: String = ""

    /// Optional shot details, for days that were injection days.
    var isInjectionDay: Bool = false
    var doseMg: Double?

    var createdAt: Date = Date()

    init(date: Date = Date(),
         weightKg: Double? = nil,
         feeling: Int = 3,
         sideEffects: [SideEffectLog] = [],
         notes: String = "",
         isInjectionDay: Bool = false,
         doseMg: Double? = nil) {
        self.date = date
        self.weightKg = weightKg
        self.feeling = feeling
        self.sideEffects = sideEffects
        self.notes = notes
        self.isInjectionDay = isInjectionDay
        self.doseMg = doseMg
        self.createdAt = Date()
    }
}

extension LogEntry {
    var day: Date { Calendar.current.startOfDay(for: date) }

    var worstSeverity: Int { sideEffects.map(\.severity).max() ?? 0 }
}

enum Feeling {
    static let range = 1...5

    static func label(_ value: Int) -> String {
        switch value {
        case 1: return "Rough"
        case 2: return "Off"
        case 3: return "OK"
        case 4: return "Good"
        default: return "Great"
        }
    }

    static func emoji(_ value: Int) -> String {
        switch value {
        case 1: return "😖"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        default: return "😄"
        }
    }
}

enum Dose {
    /// The Zepbound ladder.
    static let steps: [Double] = [2.5, 5, 7.5, 10, 12.5, 15]

    static func label(_ mg: Double) -> String {
        mg == mg.rounded() ? "\(Int(mg)) mg" : String(format: "%.1f mg", mg)
    }
}
