import Foundation
import SwiftData

// Ploché Codable kopie modelů pro zálohu do JSON. Vazby se drží přes UUID,
// které se generují při exportu (modely samy UUID neukládají).
private struct BackupData: Codable {
    var version: Int
    var clients: [ClientDTO]
    var invoices: [InvoiceDTO]
}

private struct ClientDTO: Codable {
    var id: UUID
    var name: String
    var defaultHourlyRate: Double
    var createdAt: Date
    var projects: [ProjectDTO]
}

private struct ProjectDTO: Codable {
    var name: String
    var hourlyRateOverride: Double?
    var createdAt: Date
    var entries: [EntryDTO]
}

private struct EntryDTO: Codable {
    var start: Date
    var end: Date?
    var note: String
    var isInvoiced: Bool
    var invoicedRate: Double?
    var invoiceID: UUID?
}

private struct InvoiceDTO: Codable {
    var id: UUID
    var number: Int
    var createdAt: Date
    var note: String
    var clientID: UUID?
}

enum BackupService {
    static func export(context: ModelContext) throws -> Data {
        let clients = try context.fetch(FetchDescriptor<Client>())
        let invoices = try context.fetch(FetchDescriptor<Invoice>())

        var clientIDs: [PersistentIdentifier: UUID] = [:]
        for client in clients { clientIDs[client.persistentModelID] = UUID() }
        var invoiceIDs: [PersistentIdentifier: UUID] = [:]
        for invoice in invoices { invoiceIDs[invoice.persistentModelID] = UUID() }

        let clientDTOs = clients.map { client in
            ClientDTO(
                id: clientIDs[client.persistentModelID]!,
                name: client.name,
                defaultHourlyRate: client.defaultHourlyRate,
                createdAt: client.createdAt,
                projects: client.projects.map { project in
                    ProjectDTO(
                        name: project.name,
                        hourlyRateOverride: project.hourlyRateOverride,
                        createdAt: project.createdAt,
                        entries: project.entries.map { entry in
                            EntryDTO(
                                start: entry.start,
                                end: entry.end,
                                note: entry.note,
                                isInvoiced: entry.isInvoiced,
                                invoicedRate: entry.invoicedRate,
                                invoiceID: entry.invoice.flatMap { invoiceIDs[$0.persistentModelID] }
                            )
                        }
                    )
                }
            )
        }

        let invoiceDTOs = invoices.map { invoice in
            InvoiceDTO(
                id: invoiceIDs[invoice.persistentModelID]!,
                number: invoice.number,
                createdAt: invoice.createdAt,
                note: invoice.note,
                clientID: invoice.client.flatMap { clientIDs[$0.persistentModelID] }
            )
        }

        let backup = BackupData(version: 1, clients: clientDTOs, invoices: invoiceDTOs)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    /// Obnova ze zálohy: smaže současná data a nahradí je obsahem souboru.
    static func importReplacing(_ data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        try context.delete(model: TimeEntry.self)
        try context.delete(model: Invoice.self)
        try context.delete(model: Project.self)
        try context.delete(model: Client.self)

        var invoiceMap: [UUID: Invoice] = [:]
        for dto in backup.invoices {
            let invoice = Invoice(number: dto.number, note: dto.note)
            invoice.createdAt = dto.createdAt
            context.insert(invoice)
            invoiceMap[dto.id] = invoice
        }

        for cdto in backup.clients {
            let client = Client(name: cdto.name, defaultHourlyRate: cdto.defaultHourlyRate)
            client.createdAt = cdto.createdAt
            context.insert(client)

            for idto in backup.invoices where idto.clientID == cdto.id {
                invoiceMap[idto.id]?.client = client
            }

            for pdto in cdto.projects {
                let project = Project(name: pdto.name,
                                      hourlyRateOverride: pdto.hourlyRateOverride,
                                      client: client)
                project.createdAt = pdto.createdAt
                context.insert(project)

                for edto in pdto.entries {
                    let entry = TimeEntry(start: edto.start, end: edto.end,
                                          note: edto.note, project: project)
                    entry.isInvoiced = edto.isInvoiced
                    entry.invoicedRate = edto.invoicedRate
                    if let invoiceID = edto.invoiceID {
                        entry.invoice = invoiceMap[invoiceID]
                    }
                    context.insert(entry)
                }
            }
        }

        try context.save()
    }
}
