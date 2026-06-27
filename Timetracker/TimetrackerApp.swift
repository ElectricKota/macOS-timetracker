import SwiftUI
import SwiftData

@main
struct TimetrackerApp: App {
    private let container: ModelContainer
    @State private var timer: TimerManager

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Client.self, Project.self, TimeEntry.self, Invoice.self
            )
        } catch {
            fatalError("Nepodařilo se vytvořit úložiště: \(error)")
        }
        self.container = container

        let timer = TimerManager()
        timer.configure(container.mainContext)
        _timer = State(initialValue: timer)

        let notifications = NotificationManager.shared
        notifications.setup()
        notifications.onStopRequested = { timer.stop() }
        notifications.onContinue = { timer.acknowledgeReminder() }
    }

    var body: some Scene {
        Window("Timetracker", id: "main") {
            ContentView()
                .environment(timer)
                .frame(minWidth: 860, minHeight: 540)
        }
        .modelContainer(container)
        .defaultSize(width: 980, height: 640)

        MenuBarExtra {
            MenuBarContentView()
                .environment(timer)
                .modelContainer(container)
        } label: {
            MenuBarLabel()
                .environment(timer)
        }
        .menuBarExtraStyle(.window)
    }
}
