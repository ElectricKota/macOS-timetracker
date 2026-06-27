import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    /// Vlastní sazba projektu v Kč. `nil` = dědí se z klienta.
    var hourlyRateOverride: Double?
    var createdAt: Date

    var client: Client?

    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.project)
    var entries: [TimeEntry] = []

    init(name: String, hourlyRateOverride: Double? = nil, client: Client? = nil) {
        self.name = name
        self.hourlyRateOverride = hourlyRateOverride
        self.client = client
        self.createdAt = .now
    }

    /// Skutečná sazba, kterou se počítá: vlastní, jinak zděděná z klienta.
    var effectiveRate: Double {
        hourlyRateOverride ?? client?.defaultHourlyRate ?? 0
    }

    /// Dosud nevyfakturované záznamy, nejnovější nahoře.
    var openEntries: [TimeEntry] {
        entries.filter { !$0.isInvoiced }.sorted { $0.start > $1.start }
    }
}
