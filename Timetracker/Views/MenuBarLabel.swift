import SwiftUI

/// Text v horní liště: uplynulý čas běžícího záznamu, jinak ikona hodin.
struct MenuBarLabel: View {
    @Environment(TimerManager.self) private var timer

    var body: some View {
        if timer.activeEntry != nil {
            Image(systemName: "record.circle")
            Text(Format.hm(timer.elapsed))
        } else {
            Image(systemName: "clock")
        }
    }
}
