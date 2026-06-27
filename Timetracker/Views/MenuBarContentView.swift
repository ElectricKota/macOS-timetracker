import SwiftUI
import SwiftData
import AppKit

/// Obsah popoveru po kliknutí na ikonu v liště – stav časovače,
/// rychlé spuštění projektů a otevření hlavního okna.
struct MenuBarContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerManager.self) private var timer
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \Client.name) private var clients: [Client]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            currentSection
            Divider()
            quickStartSection
            Divider()
            HStack {
                Button("Otevřít Timetracker") {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                Spacer()
                Button("Konec") { NSApplication.shared.terminate(nil) }
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 300)
    }

    @ViewBuilder
    private var currentSection: some View {
        if let entry = timer.activeEntry {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.project?.client?.name ?? "—")
                    .font(.caption).foregroundStyle(.secondary)
                Text(entry.project?.name ?? "Projekt")
                    .font(.headline)
                HStack {
                    Text(Format.hms(timer.elapsed))
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                    Spacer()
                    Button(role: .destructive) {
                        timer.stop()
                    } label: {
                        Label("Zastavit", systemImage: "stop.fill")
                    }
                }
            }
        } else {
            Label("Žádný běžící časovač", systemImage: "pause.circle")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var quickStartSection: some View {
        if clients.isEmpty {
            Text("Zatím nemáš žádné projekty.\nOtevři Timetracker a založ klienta.")
                .font(.caption).foregroundStyle(.secondary)
        } else {
            Text("Rychlé spuštění").font(.caption).foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(clients) { client in
                        ForEach(client.projects.sorted { $0.name < $1.name }) { project in
                            Button {
                                timer.start(project)
                            } label: {
                                HStack {
                                    Image(systemName: timer.isRunning(project) ? "record.circle" : "play.fill")
                                        .foregroundStyle(timer.isRunning(project) ? .red : .accentColor)
                                    Text("\(client.name) · \(project.name)")
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .frame(maxHeight: 220)
        }
    }
}
