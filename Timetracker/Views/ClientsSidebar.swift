import SwiftUI
import SwiftData

struct ClientsSidebar: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Client.name) private var clients: [Client]
    @Binding var selection: PersistentIdentifier?

    @State private var editingClient: Client?
    @State private var showingNew = false

    var body: some View {
        List(selection: $selection) {
            ForEach(clients) { client in
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                    Text("\(client.projects.count) projektů · \(Format.money(client.defaultHourlyRate))/h")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(client.persistentModelID)
                .contextMenu {
                    Button("Upravit") { editingClient = client }
                    Button("Smazat", role: .destructive) { delete(client) }
                }
            }
        }
        .navigationTitle("Klienti")
        .toolbar {
            ToolbarItem {
                Button { showingNew = true } label: {
                    Label("Nový klient", systemImage: "plus")
                }
            }
        }
        .overlay {
            if clients.isEmpty {
                ContentUnavailableView("Žádní klienti", systemImage: "person.2",
                                       description: Text("Přidej prvního tlačítkem +."))
            }
        }
        .sheet(isPresented: $showingNew) { ClientEditSheet(client: nil) }
        .sheet(item: $editingClient) { ClientEditSheet(client: $0) }
    }

    private func delete(_ client: Client) {
        if selection == client.persistentModelID { selection = nil }
        context.delete(client)
    }
}
