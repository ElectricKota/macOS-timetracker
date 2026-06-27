import Foundation
import SwiftData

@Model
final class Client {
    var name: String
    /// Výchozí hodinová sazba v Kč. Projekty ji dědí, pokud nemají vlastní.
    var defaultHourlyRate: Double
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Project.client)
    var projects: [Project] = []

    @Relationship(deleteRule: .cascade, inverse: \Invoice.client)
    var invoices: [Invoice] = []

    init(name: String, defaultHourlyRate: Double = 0) {
        self.name = name
        self.defaultHourlyRate = defaultHourlyRate
        self.createdAt = .now
    }

    /// Součet částek z dosud nevyfakturovaných (uzavřených i běžících) časů.
    var unbilledAmount: Double {
        projects.flatMap(\.entries).filter { !$0.isInvoiced }.reduce(0) { $0 + $1.amount }
    }

    /// Součet všeho, co už bylo vyfakturováno.
    var invoicedAmount: Double {
        projects.flatMap(\.entries).filter { $0.isInvoiced }.reduce(0) { $0 + $1.amount }
    }
}
