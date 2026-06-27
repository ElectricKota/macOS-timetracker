import SwiftUI
import SwiftData

/// Třísloupcové rozložení: Klienti › Projekty › Detail projektu.
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Client.name) private var clients: [Client]

    @State private var selectedClientID: PersistentIdentifier?
    @State private var selectedProjectID: PersistentIdentifier?

    private var selectedClient: Client? {
        clients.first { $0.persistentModelID == selectedClientID }
    }

    private var selectedProject: Project? {
        selectedClient?.projects.first { $0.persistentModelID == selectedProjectID }
    }

    var body: some View {
        NavigationSplitView {
            ClientsSidebar(selection: $selectedClientID)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        } content: {
            if let client = selectedClient {
                ProjectsColumn(client: client, selection: $selectedProjectID)
                    .navigationSplitViewColumnWidth(min: 240, ideal: 280)
            } else {
                ContentUnavailableView("Vyber klienta",
                                       systemImage: "person.2",
                                       description: Text("Nebo vlevo nahoře založ nového."))
            }
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else {
                ContentUnavailableView("Vyber projekt",
                                       systemImage: "folder",
                                       description: Text("Časy se trackují uvnitř projektu."))
            }
        }
        .onChange(of: selectedClientID) { selectedProjectID = nil }
    }
}
