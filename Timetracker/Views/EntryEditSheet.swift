import SwiftUI
import SwiftData

/// Úprava záznamu – buď zadáním „od–do“, nebo celkové délky (dopočítá „do“).
struct EntryEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: TimeEntry

    private enum Mode: String, CaseIterable, Identifiable {
        case range = "Od–Do"
        case total = "Celkem"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .range
    @State private var start = Date()
    @State private var end = Date()
    @State private var hours = 0
    @State private var minutes = 0
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upravit čas").font(.headline)

            Form {
                TextField("Popis", text: $note)

                DatePicker("Začátek", selection: $start)

                Picker("Zadat jako", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .range:
                    DatePicker("Konec", selection: $end)
                case .total:
                    HStack {
                        Text("Délka")
                        Spacer()
                        Stepper("\(hours) h", value: $hours, in: 0...99)
                        Stepper("\(minutes) min", value: $minutes, in: 0...59)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Zrušit") { dismiss() }
                Button("Uložit") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear(perform: load)
    }

    private var computedEnd: Date {
        switch mode {
        case .range: return end
        case .total: return start.addingTimeInterval(TimeInterval(hours * 3600 + minutes * 60))
        }
    }

    private var isValid: Bool { computedEnd > start }

    private func load() {
        start = entry.start
        let resolvedEnd = entry.end ?? entry.start.addingTimeInterval(3600)
        end = resolvedEnd
        let total = Int(resolvedEnd.timeIntervalSince(entry.start))
        hours = max(0, total / 3600)
        minutes = max(0, (total % 3600) / 60)
        note = entry.note
    }

    private func save() {
        entry.start = start
        entry.end = computedEnd
        entry.note = note
        try? context.save()
        dismiss()
    }
}
