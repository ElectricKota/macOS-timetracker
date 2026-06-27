import Foundation
import SwiftData

@Model
final class TimeEntry {
    var start: Date
    /// `nil` = časovač právě běží.
    var end: Date?
    var note: String

    var isInvoiced: Bool
    /// Sazba zafixovaná v okamžiku fakturace, aby pozdější změna sazby
    /// neměnila už vystavené faktury.
    var invoicedRate: Double?

    var project: Project?
    var invoice: Invoice?

    init(start: Date = .now, end: Date? = nil, note: String = "", project: Project? = nil) {
        self.start = start
        self.end = end
        self.note = note
        self.isInvoiced = false
        self.project = project
    }

    var isRunning: Bool { end == nil }

    /// Délka záznamu. U běžícího se počítá k aktuálnímu času.
    var duration: TimeInterval {
        (end ?? Date()).timeIntervalSince(start)
    }

    /// Použitá sazba: zafixovaná při fakturaci, jinak aktuální sazba projektu.
    var rate: Double {
        invoicedRate ?? project?.effectiveRate ?? 0
    }

    var amount: Double {
        duration / 3600.0 * rate
    }
}
