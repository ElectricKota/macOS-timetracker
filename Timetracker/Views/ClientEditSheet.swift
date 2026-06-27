import SwiftUI
import SwiftData

struct ClientEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// `nil` = zakládáme nového klienta.
    let client: Client?

    @State private var name = ""
    @State private var rate = 0.0

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(client == nil ? "Nový klient" : "Upravit klienta").font(.headline)

            Form {
                TextField("Jméno", text: $name)
                TextField("Hodinová sazba (Kč)", value: $rate, format: .number)
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
        .frame(width: 380)
        .onAppear {
            if let client {
                name = client.name
                rate = client.defaultHourlyRate
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let client {
            client.name = trimmed
            client.defaultHourlyRate = rate
        } else {
            context.insert(Client(name: trimmed, defaultHourlyRate: rate))
        }
        dismiss()
    }
}
