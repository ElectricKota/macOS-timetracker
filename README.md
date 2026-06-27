# Timetracker

Nativní macOS appka pro sledování fakturovatelného času. Žije v horní liště
(menu bar), bez ikony v docku. SwiftUI + SwiftData, macOS 14+.

## Co umí

- **Menu bar ikona** s uplynulým časem `h:mm` běžícího záznamu. Po kliknutí
  panel se stavem, rychlým spuštěním projektů a otevřením hlavního okna.
- **Hierarchie** Klient › Projekt › Časy ve třísloupcovém okně.
- **Hodinová sazba** na projektu s děděním z klienta (jde přepsat).
- **Jeden časovač naráz** – spuštění jiného projektu předchozí uzavře.
  Po restartu appky naváže na rozběhnutý čas.
- **Úprava záznamů** zadáním *Od–Do* nebo *Celkem* (dopočítá konec) + popis.
  Ruční přidání času pro případ, že zapomeneš spustit.
- **Fakturace** – uzavřené časy se zamknou do faktury, zafixuje se sazba a dál
  jsou jen v sekci „Vyfakturováno" s částkou; nejdou už upravit ani znovu uzavřít.
- **Připomínka po 2 hodinách** „Trackuješ ještě?" jako systémová notifikace
  s tlačítky Pokračovat / Zastavit; časovač mezitím běží dál.

## Build & spuštění

Otevři `Timetracker.xcodeproj` v Xcode a stiskni **Cmd+R**, nebo z terminálu:

```bash
xcodebuild -project Timetracker.xcodeproj -scheme Timetracker \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/Timetracker.app
```

Při prvním spuštění potvrď systémový dotaz na povolení notifikací (jinak
nepřijde dvouhodinová připomínka).

## Struktura

```
Timetracker/
  Models/      Client, Project, TimeEntry, Invoice  (SwiftData @Model)
  Managers/    TimerManager, NotificationManager
  Views/       menu bar + hlavní okno
  Format.swift formátování času a Kč
```

Projekt používá Xcode „synchronized folder" – nový `.swift` soubor stačí
přidat do složky `Timetracker/`, do projektu se zařadí automaticky.
