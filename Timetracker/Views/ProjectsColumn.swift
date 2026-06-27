import SwiftUI
import SwiftData

struct ProjectsColumn: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerManager.self) private var timer
    @Bindable var client: Client
    @Binding var selection: PersistentIdentifier?

    @State private var editingProject: Project?
    @State private var showingNew = false

    private var projects: [Project] {
        client.projects.sorted { $0.name < $1.name }
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
                    let open = project.openEntries.reduce(0) { $0 + $1.amount }
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
                Text(Format.money(client.unbilledAmount)).fontWeight(.medium)
            }
            HStack {
                Text("Vyfakturováno").foregroundStyle(.secondary)
                Spacer()
                Text(Format.money(client.invoicedAmount))
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
