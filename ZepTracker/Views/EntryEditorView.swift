import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.pounds.rawValue

    let entry: LogEntry
    private let isNew: Bool

    @State private var date: Date
    @State private var weightText: String
    @State private var feeling: Int
    @State private var sideEffects: [SideEffectLog]
    @State private var notes: String
    @State private var isInjectionDay: Bool
    @State private var doseMg: Double?

    @State private var showingEffectPicker = false
    @State private var showingDeleteConfirm = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    init(entry: LogEntry) {
        self.entry = entry
        self.isNew = entry.modelContext == nil
        _date = State(initialValue: entry.date)
        _feeling = State(initialValue: entry.feeling)
        _sideEffects = State(initialValue: entry.sideEffects)
        _notes = State(initialValue: entry.notes)
        _isInjectionDay = State(initialValue: entry.isInjectionDay)
        _doseMg = State(initialValue: entry.doseMg)

        let saved = UserDefaults.standard.string(forKey: "weightUnit")
        let u = WeightUnit(rawValue: saved ?? "") ?? .pounds
        _weightText = State(initialValue: entry.weightKg.map { u.format(kg: $0, includeUnit: false) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)

                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("—", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                            .monospacedDigit()
                        Text(unit.short)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("How do I feel?") {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(Feeling.range, id: \.self) { value in
                                Button {
                                    feeling = value
                                } label: {
                                    Text(Feeling.emoji(value))
                                        .font(.system(size: 28))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            feeling == value ? Color.teal.opacity(0.18) : Color.clear,
                                            in: .rect(cornerRadius: 12)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(feeling == value ? Color.teal : .clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(Feeling.label(feeling))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Side effects") {
                    ForEach($sideEffects) { $effect in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: SideEffectCatalog.symbol(for: effect.kind))
                                    .foregroundStyle(.teal)
                                    .frame(width: 22)
                                Text(effect.kind)
                                Spacer()
                            }
                            Picker("Severity", selection: $effect.severity) {
                                Text("Mild").tag(1)
                                Text("Moderate").tag(2)
                                Text("Severe").tag(3)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { sideEffects.remove(atOffsets: $0) }

                    Button {
                        showingEffectPicker = true
                    } label: {
                        Label(sideEffects.isEmpty ? "Add a side effect" : "Add another", systemImage: "plus.circle")
                    }
                }

                Section("Shot") {
                    Toggle("Injection day", isOn: $isInjectionDay.animation())
                    if isInjectionDay {
                        Picker("Dose", selection: $doseMg) {
                            Text("Not set").tag(Double?.none)
                            ForEach(Dose.steps, id: \.self) { mg in
                                Text(Dose.label(mg)).tag(Double?.some(mg))
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if !isNew {
                    Section {
                        Button("Delete entry", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isNew ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold()
                }
            }
            .sheet(isPresented: $showingEffectPicker) {
                SideEffectPicker(selected: $sideEffects)
            }
            .confirmationDialog("Delete this entry?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    context.delete(entry)
                    dismiss()
                }
            }
        }
    }

    private func save() {
        entry.date = date
        entry.feeling = feeling
        entry.sideEffects = sideEffects
        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.isInjectionDay = isInjectionDay
        entry.doseMg = isInjectionDay ? doseMg : nil

        let cleaned = weightText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        entry.weightKg = Double(cleaned).map { unit.toKg($0) }

        if isNew { context.insert(entry) }
        dismiss()
    }
}

struct SideEffectPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: [SideEffectLog]
    @State private var custom = ""

    private var alreadyLogged: Set<String> { Set(selected.map(\.kind)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Something else…", text: $custom)
                        Button("Add") { add(custom) }
                            .disabled(custom.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Common") {
                    ForEach(SideEffectCatalog.common, id: \.self) { kind in
                        Button { add(kind) } label: {
                            HStack {
                                Image(systemName: SideEffectCatalog.symbol(for: kind))
                                    .foregroundStyle(.teal)
                                    .frame(width: 22)
                                Text(kind).foregroundStyle(.primary)
                                Spacer()
                                if alreadyLogged.contains(kind) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                        .disabled(alreadyLogged.contains(kind))
                    }
                }
            }
            .navigationTitle("Side Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func add(_ kind: String) {
        let name = kind.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !alreadyLogged.contains(name) else { return }
        selected.append(SideEffectLog(kind: name, severity: 1))
        custom = ""
        dismiss()
    }
}
