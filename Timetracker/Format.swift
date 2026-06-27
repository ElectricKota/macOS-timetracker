import Foundation

/// Sjednocené formátování času a peněz pro celou aplikaci.
enum Format {
    /// "h:mm" – pro menu bar a souhrny.
    static func hm(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%d:%02d", s / 3600, (s % 3600) / 60)
    }

    /// "h:mm:ss" – pro běžící časovač v detailu.
    static func hms(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }

    /// Částka v Kč bez haléřů, např. "5 250 Kč".
    static func money(_ v: Double) -> String {
        v.formatted(.currency(code: "CZK").precision(.fractionLength(0)))
    }

    /// Krátký čas, např. "9:05".
    static func time(_ d: Date) -> String {
        d.formatted(.dateTime.hour().minute())
    }

    /// Datum + čas, např. "27. 6. 9:05".
    static func dateTime(_ d: Date) -> String {
        d.formatted(.dateTime.day().month().hour().minute())
    }

    /// Jen datum, např. "27. 6. 2026".
    static func date(_ d: Date) -> String {
        d.formatted(.dateTime.day().month().year())
    }
}
