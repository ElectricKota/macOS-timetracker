import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerManager.self) private var timer
    @Bindable var project: Project

    @State private var editingEntry: TimeEntry?
    @State private var editingProject = false
    @State private var showInvoiceConfirm = false

    private var openEntries: [TimeEntry] { project.openEntries }

    private var invoices: [Invoice] {
        var seen = Set<PersistentIdentifier>()
        var result: [Invoice] = []
        for entry in project.entries where entry.isInvoiced {
            if let inv = entry.invoice, seen.insert(inv.persistentModelID).inserted {
                result.append(inv)
            }
        }
        return result.sorted { $0.number > $1.number }
    }

    /// Lze fakturovat jen uzavřené, dosud nevyfakturované záznamy.
    private var invoiceableCount: Int {
        project.entries.filter { !$0.isInvoiced && $0.end != nil }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                timerCard
                openSection
                if !invoices.isEmpty { invoicesSection }
            }
            .padding(20)
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem {
                Button { addManualEntry() } label: {
                    Label("Přidat čas ručně", systemImage: "plus")
                }
            }
            ToolbarItem {
                Button { editingProject = true } label: {
                    Label("Upravit projekt", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(item: $editingEntry) { EntryEditSheet(entry: $0) }
        .sheet(isPresented: $editingProject) {
            ProjectEditSheet(client: project.client, project: project)
        }
        .confirmationDialog(
            "Vyfakturovat \(invoiceableCount) \(invoiceableCount == 1 ? "záznam" : "záznamů")?",
            isPresented: $showInvoiceConfirm, titleVisibility: .visible
        ) {
            Button("Vyfakturovat") { invoiceOpen() }
            Button("Zrušit", role: .cancel) {}
        } message: {
            Text("Záznamy se uzamknou a už nepůjdou upravit ani znovu uzavřít.")
        }
    }

    // MARK: - Časovač

    private var timerCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.client?.name ?? "—")
                    .font(.caption).foregroundStyle(.secondary)
                Text("\(Format.money(project.effectiveRate))/h"
                     + (project.hourlyRateOverride == nil ? " (zděděno)" : ""))
                    .font(.caption).foregroundStyle(.secondary)
                if timer.isRunning(project) {
                    Text(Format.hms(timer.elapsed))
                        .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                } else {
                    Text("0:00:00")
                        .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if timer.isRunning(project) {
                Button(role: .destructive) { timer.stop() } label: {
                    Label("Zastavit", systemImage: "stop.fill").padding(6)
                }
                .controlSize(.large)
            } else {
                Button { timer.start(project) } label: {
                    Label("Spustit", systemImage: "play.fill").padding(6)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Neuzavřené časy

    private var openSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Neuzavřené časy").font(.headline)
                Spacer()
                if invoiceableCount > 0 {
                    Button { showInvoiceConfirm = true } label: {
                        Label("Vyfakturovat vše", systemImage: "checkmark.seal")
                    }
                }
            }

            if openEntries.isEmpty {
                Text("Žádné nevyfakturované časy.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(openEntries) { entry in
                    EntryRow(entry: entry)
                        .contextMenu {
                            if !entry.isRunning {
                                Button("Upravit") { editingEntry = entry }
                            }
                            Button("Smazat", role: .destructive) { context.delete(entry) }
                        }
                        .onTapGesture(count: 2) {
                            if !entry.isRunning { editingEntry = entry }
                        }
                }
                totalsRow(
                    duration: openEntries.reduce(0) { $0 + $1.duration },
                    amount: openEntries.reduce(0) { $0 + $1.amount }
                )
            }
        }
    }

    // MARK: - Faktury

    private var invoicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vyfakturováno").font(.headline)
            ForEach(invoices) { invoice in
                let entries = invoice.entries(of: project)
                let amount = entries.reduce(0) { $0 + $1.amount }
                let duration = entries.reduce(0) { $0 + $1.duration }
                DisclosureGroup {
                    ForEach(entries) { entry in
                        EntryRow(entry: entry).padding(.leading, 4)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Faktura č. \(invoice.number)")
                            Text(Format.date(invoice.createdAt))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Format.hm(duration)).foregroundStyle(.secondary)
                        Text(Format.money(amount)).fontWeight(.medium)
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func totalsRow(duration: TimeInterval, amount: Double) -> some View {
        HStack {
            Text("Celkem").fontWeight(.medium)
            Spacer()
            Text(Format.hm(duration)).foregroundStyle(.secondary)
            Text(Format.money(amount)).fontWeight(.semibold)
        }
        .padding(.top, 4)
    }

    // MARK: - Akce

    private func addManualEntry() {
        let entry = TimeEntry(
            start: Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now,
            end: .now,
            project: project
        )
        context.insert(entry)
        editingEntry = entry
    }

    private func invoiceOpen() {
        let toInvoice = project.entries.filter { !$0.isInvoiced && $0.end != nil }
        guard !toInvoice.isEmpty else { return }

        let allInvoices = (try? context.fetch(FetchDescriptor<Invoice>())) ?? []
        let number = (allInvoices.map(\.number).max() ?? 0) + 1

        let invoice = Invoice(number: number, client: project.client)
        context.insert(invoice)
        for entry in toInvoice {
            entry.isInvoiced = true
            entry.invoicedRate = project.effectiveRate
            entry.invoice = invoice
        }
        try? context.save()
    }
}

/// Řádek jednoho časového záznamu.
struct EntryRow: View {
    @Environment(TimerManager.self) private var timer
    @Bindable var entry: TimeEntry

    private var duration: TimeInterval {
        entry.isRunning ? timer.now.timeIntervalSince(entry.start) : entry.duration
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if entry.isRunning {
                        Image(systemName: "record.circle").foregroundStyle(.red)
                    }
                    Text(entry.note.isEmpty ? "Bez popisu" : entry.note)
                        .foregroundStyle(entry.note.isEmpty ? .secondary : .primary)
                }
                Text(rangeText)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(Format.hm(duration)).monospacedDigit()
            Text(Format.money(duration / 3600 * entry.rate))
                .foregroundStyle(.secondary)
                .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }

    private var rangeText: String {
        if entry.isRunning {
            return "\(Format.dateTime(entry.start)) – běží"
        }
        if let end = entry.end {
            return "\(Format.dateTime(entry.start)) – \(Format.time(end))"
        }
        return Format.dateTime(entry.start)
    }
}
