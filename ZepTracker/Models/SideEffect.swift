import Foundation

/// A side effect logged on a single entry, with how bad it was.
struct SideEffectLog: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var kind: String
    var severity: Int   // 1 = mild, 2 = moderate, 3 = severe

    var severityLabel: String {
        switch severity {
        case 1: return "Mild"
        case 2: return "Moderate"
        default: return "Severe"
        }
    }
}

enum SideEffectCatalog {
    /// The usual suspects for tirzepatide, roughly in order of how often they come up.
    static let common: [String] = [
        "Nausea",
        "Fatigue",
        "Constipation",
        "Diarrhea",
        "Heartburn / reflux",
        "Bloating / gas",
        "Sulfur burps",
        "Headache",
        "Dizziness",
        "Appetite loss",
        "Injection site reaction",
        "Stomach pain",
        "Vomiting",
        "Muscle cramps",
        "Trouble sleeping"
    ]

    static func symbol(for kind: String) -> String {
        switch kind {
        case "Nausea", "Vomiting": return "wind"
        case "Fatigue", "Trouble sleeping": return "moon.zzz"
        case "Constipation", "Diarrhea", "Bloating / gas", "Sulfur burps", "Stomach pain": return "circle.dotted"
        case "Heartburn / reflux": return "flame"
        case "Headache", "Dizziness": return "brain.head.profile"
        case "Appetite loss": return "fork.knife"
        case "Injection site reaction": return "cross.vial"
        case "Muscle cramps": return "figure.walk"
        default: return "exclamationmark.circle"
        }
    }
}
