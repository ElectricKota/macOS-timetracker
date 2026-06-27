import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

/// Třísloupcové rozložení: Klienti › Projekty › Detail projektu.
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerManager.self) private var timer
    @Query(sort: \Client.name) private var clients: [Client]

    @State private var selectedClientID: PersistentIdentifier?
    @State private var selectedProjectID: PersistentIdentifier?

    @State private var confirmImport = false
    @State private var errorMessage: String?

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Zálohovat data…") { exportBackup() }
                    Button("Obnovit ze zálohy…") { confirmImport = true }
                } label: {
                    Label("Záloha", systemImage: "externaldrive")
                }
            }
        }
        .confirmationDialog("Obnovit ze zálohy?",
                            isPresented: $confirmImport, titleVisibility: .visible) {
            Button("Vybrat soubor…") { importBackup() }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Současná data se nahradí obsahem zálohy. Tahle akce nejde vrátit.")
        }
        .alert("Něco se nepovedlo", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func exportBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "Timetracker-zaloha-\(Format.date(.now)).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try BackupService.export(context: context)
            try data.write(to: url)
        } catch {
            errorMessage = "Zálohu se nepodařilo uložit: \(error.localizedDescription)"
        }
    }

    private func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            timer.stop()
            try BackupService.importReplacing(data, context: context)
            selectedClientID = nil
            selectedProjectID = nil
            timer.configure(context)
        } catch {
            errorMessage = "Zálohu se nepodařilo obnovit: \(error.localizedDescription)"
        }
    }
}
