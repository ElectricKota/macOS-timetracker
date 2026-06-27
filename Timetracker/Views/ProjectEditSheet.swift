import SwiftUI
import SwiftData

struct ProjectEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let client: Client?
    /// `nil` = zakládáme nový projekt.
    let project: Project?

    @State private var name = ""
    @State private var useCustomRate = false
    @State private var rate = 0.0

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var inheritedRate: Double { client?.defaultHourlyRate ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(project == nil ? "Nový projekt" : "Upravit projekt").font(.headline)

            Form {
                TextField("Název", text: $name)
                Toggle("Vlastní sazba", isOn: $useCustomRate)
                if useCustomRate {
                    TextField("Hodinová sazba (Kč)", value: $rate, format: .number)
                } else {
                    LabeledContent("Sazba (z klienta)", value: "\(Format.money(inheritedRate))/h")
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
        .frame(width: 400)
        .onAppear {
            if let project {
                name = project.name
                if let override = project.hourlyRateOverride {
                    useCustomRate = true
                    rate = override
                } else {
                    rate = inheritedRate
                }
            } else {
                rate = inheritedRate
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let override = useCustomRate ? rate : nil
        if let project {
            project.name = trimmed
            project.hourlyRateOverride = override
        } else {
            let new = Project(name: trimmed, hourlyRateOverride: override, client: client)
            context.insert(new)
        }
        dismiss()
    }
}
