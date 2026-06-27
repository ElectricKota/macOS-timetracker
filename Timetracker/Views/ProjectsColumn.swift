import SwiftUI
import SwiftData

struct ProjectsColumn: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerManager.self) private var timer
    @Bindable var client: Client
    @Binding var selection: PersistentIdentifier?

    // Seznamy řídíme přes @Query, ne přes procházení vazby `client.projects` –
    // @Query se spolehlivě překreslí při každé změně v databázi.
    @Query(sort: \Project.name) private var allProjects: [Project]
    @Query private var allEntries: [TimeEntry]

    @State private var editingProject: Project?
    @State private var showingNew = false

    private var clientID: PersistentIdentifier { client.persistentModelID }

    private var projects: [Project] {
        allProjects.filter { $0.client?.persistentModelID == clientID }
    }

    private func openAmount(of project: Project) -> Double {
        allEntries
            .filter { $0.project?.persistentModelID == project.persistentModelID && !$0.isInvoiced }
            .reduce(0) { $0 + $1.amount }
    }

    private var clientEntries: [TimeEntry] {
        allEntries.filter { $0.project?.client?.persistentModelID == clientID }
    }

    private var unbilled: Double {
        clientEntries.filter { !$0.isInvoiced }.reduce(0) { $0 + $1.amount }
    }

    private var invoiced: Double {
        clientEntries.filter { $0.isInvoiced }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(projects) { project in
                HStack {
                    if timer.isRunning(project) {
                        Image(systemName: "record.circle").foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                        Text("\(Format.money(project.effectiveRate))/h")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    let open = openAmount(of: project)
                    if open > 0 {
                        Text(Format.money(open))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tag(project.persistentModelID)
                .contextMenu {
                    Button("Upravit") { editingProject = project }
                    Button("Smazat", role: .destructive) { delete(project) }
                }
            }
        }
        .navigationTitle(client.name)
        .safeAreaInset(edge: .bottom) { summary }
        .toolbar {
            ToolbarItem {
                Button { showingNew = true } label: {
                    Label("Nový projekt", systemImage: "plus")
                }
            }
        }
        .overlay {
            if projects.isEmpty {
                ContentUnavailableView("Žádné projekty", systemImage: "folder.badge.plus",
                                       description: Text("Přidej projekt tlačítkem +."))
            }
        }
        .sheet(isPresented: $showingNew) { ProjectEditSheet(client: client, project: nil) }
        .sheet(item: $editingProject) { ProjectEditSheet(client: client, project: $0) }
    }

    private var summary: some View {
        VStack(spacing: 4) {
            Divider()
            HStack {
                Text("Nevyfakturováno").foregroundStyle(.secondary)
                Spacer()
                Text(Format.money(unbilled)).fontWeight(.medium)
            }
            HStack {
                Text("Vyfakturováno").foregroundStyle(.secondary)
                Spacer()
                Text(Format.money(invoiced))
            }
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .background(.bar)
    }

    private func delete(_ project: Project) {
        if selection == project.persistentModelID { selection = nil }
        context.delete(project)
    }
}
