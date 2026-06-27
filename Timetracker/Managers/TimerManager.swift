import Foundation
import SwiftData
import Observation

/// Drží jeden běžící časovač, jednou za sekundu posouvá `now` (kvůli živému
/// zobrazení) a po dvou hodinách vyvolá připomínku „trackuješ ještě?“.
@MainActor
@Observable
final class TimerManager {
    /// Právě běžící záznam (s `end == nil`), nebo `nil` když nic neběží.
    var activeEntry: TimeEntry?
    /// Aktuální čas, aktualizovaný každou sekundu – pohání živé počítadlo.
    var now: Date = .now

    /// Připomínka se ozve po této době od posledního potvrzení.
    let reminderInterval: TimeInterval = 2 * 60 * 60

    private var ticker: Timer?
    private var lastReminderAt: Date?
    private var modelContext: ModelContext?

    func configure(_ context: ModelContext) {
        modelContext = context
        restoreRunning()
    }

    /// Po restartu appky najde rozběhnutý záznam a naváže na něj.
    private func restoreRunning() {
        guard let modelContext else { return }
        let all = (try? modelContext.fetch(FetchDescriptor<TimeEntry>())) ?? []
        if let running = all.first(where: { $0.end == nil }) {
            activeEntry = running
            lastReminderAt = .now
            startTicking()
        }
    }

    /// Uplynulý čas běžícího záznamu.
    var elapsed: TimeInterval {
        guard let activeEntry else { return 0 }
        return now.timeIntervalSince(activeEntry.start)
    }

    func isRunning(_ project: Project) -> Bool {
        activeEntry?.project?.persistentModelID == project.persistentModelID
    }

    /// Spustí časovač pro projekt. Případný běžící časovač nejdřív uzavře.
    func start(_ project: Project) {
        guard let modelContext else { return }
        stop()
        let entry = TimeEntry(start: .now, project: project)
        modelContext.insert(entry)
        activeEntry = entry
        lastReminderAt = .now
        try? modelContext.save()
        startTicking()
    }

    /// Uzavře běžící časovač (nastaví `end`).
    func stop() {
        if let activeEntry {
            activeEntry.end = .now
        }
        activeEntry = nil
        try? modelContext?.save()
        stopTicking()
    }

    /// Uživatel potvrdil, že stále pracuje – posuneme okno připomínky.
    func acknowledgeReminder() {
        lastReminderAt = .now
    }

    private func startTicking() {
        ticker?.invalidate()
        now = .now
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func tick() {
        now = .now
        guard let entry = activeEntry, let last = lastReminderAt else { return }
        if now.timeIntervalSince(last) >= reminderInterval {
            lastReminderAt = now
            NotificationManager.shared.sendReminder(
                projectName: entry.project?.name ?? "Projekt",
                elapsed: Format.hm(elapsed)
            )
        }
    }

    private func stopTicking() {
        ticker?.invalidate()
        ticker = nil
        now = .now
    }
}
