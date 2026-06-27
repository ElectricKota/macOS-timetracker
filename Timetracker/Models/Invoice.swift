import Foundation
import SwiftData

/// Uzavřená dávka vyfakturovaných časů. Po vytvoření se její záznamy
/// označí jako vyfakturované a už nejdou znovu uzavřít ani upravit.
@Model
final class Invoice {
    var number: Int
    var createdAt: Date
    var note: String

    var client: Client?

    @Relationship(deleteRule: .nullify, inverse: \TimeEntry.invoice)
    var entries: [TimeEntry] = []

    init(number: Int, client: Client? = nil, note: String = "") {
        self.number = number
        self.createdAt = .now
        self.client = client
        self.note = note
    }

    var totalDuration: TimeInterval {
        entries.reduce(0) { $0 + $1.duration }
    }

    var totalAmount: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    /// Záznamy z konkrétního projektu (faktura může mít víc projektů klienta).
    func entries(of project: Project) -> [TimeEntry] {
        entries
            .filter { $0.project?.persistentModelID == project.persistentModelID }
            .sorted { $0.start > $1.start }
    }
}
